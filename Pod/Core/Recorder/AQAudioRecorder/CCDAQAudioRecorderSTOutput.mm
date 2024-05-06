//
//  CCDAQAudioRecorderSTOutput.m
//  Pods
//
//  Created by ruhong zhu on 2021/7/3.
//

#import "CCDAQAudioRecorderSTOutput.h"
#import "SoundTouch.h"

void *CCDCreateWaveHeader(int fileLength,
                          short channel,
                          int sampleRate,
                          short bitPerSample)
{
    CCDAudioWaveHeader *header = (CCDAudioWaveHeader *)malloc(sizeof(CCDAudioWaveHeader));
    
    if (header == NULL) {
        return NULL;
    }
    
    // RIFF
    header->riff[0] = 'R';
    header->riff[1] = 'I';
    header->riff[2] = 'F';
    header->riff[3] = 'F';
    
    // file length
    header->fileLength = fileLength + (44 - 8);
    
    // WAVE
    header->wavTag[0] = 'W';
    header->wavTag[1] = 'A';
    header->wavTag[2] = 'V';
    header->wavTag[3] = 'E';
    
    // fmt
    header->fmt[0] = 'f';
    header->fmt[1] = 'm';
    header->fmt[2] = 't';
    header->fmt[3] = ' ';
    
    header->size = 16;
    header->formatTag = 1;
    header->channel = channel;
    header->sampleRate = sampleRate;
    header->bitPerSample = bitPerSample;
    header->blockAlign = (short)(header->channel * header->bitPerSample / 8);
    header->bytePerSec = header->blockAlign * header->sampleRate;
    
    // data
    header->data[0] = 'd';
    header->data[1] = 'a';
    header->data[2] = 't';
    header->data[3] = 'a';
    
    // data size
    header->dataSize = fileLength;
    
    return header;
}

@interface CCDAQAudioRecorderSTOutput ()
{
    FILE *_file;
    soundtouch::SoundTouch _st;
    CCDAudioWaveHeader *_header;
}

@end

@implementation CCDAQAudioRecorderSTOutput

@synthesize audioType = _audioType;
@synthesize audioFormat = _audioFormat;
@synthesize filePath = _filePath;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _audioType = CCDAudioTypeWav;
        
        AudioStreamBasicDescription tempAudioFormat;
        memset(&tempAudioFormat, 0, sizeof(tempAudioFormat));
        // 设置formatID
        tempAudioFormat.mFormatID = kAudioFormatLinearPCM;
        // 采样率的意思是每秒需要采集的帧数 [AVAudioSession sharedInstance].sampleRate;
        tempAudioFormat.mSampleRate = 8000;
        // 设置通道数 (UInt32)[AVAudioSession sharedInstance].inputNumberOfChannels;
        tempAudioFormat.mChannelsPerFrame = 1;
        // if we want pcm, default to signed 16-bit little-endian
        tempAudioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        // 每个通道里，一帧采集的bit数目
        tempAudioFormat.mBitsPerChannel = 16;
        // 结果分析: 8bit为1byte，即为1个通道里1帧需要采集2byte数据，再*通道数，即为所有通道采集的byte数目。
        // 所以这里结果赋值给每帧需要采集的byte数目，然后这里的packet也等于一帧的数据。
        tempAudioFormat.mBytesPerPacket = tempAudioFormat.mBytesPerFrame = (tempAudioFormat.mBitsPerChannel / 8) * tempAudioFormat.mChannelsPerFrame;
        tempAudioFormat.mFramesPerPacket = 1;
        _audioFormat = tempAudioFormat;
        
        // sound touch 变声
        _tempo = 0;
        _pitchSemiTones = 0;
        _rateChange = 0;
        
        NSString *name = [NSString stringWithFormat:@"audio_output.wav"];
        _filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
    }
    return self;
}

#pragma mark - CCDAudioRecorderOutput

- (BOOL)openAudioFile
{
    /**
     相关参数概念
     -tempo = n 将声音速度更改n个百分点（n = -95.0 .. +5000.0％）
     -pitch = n 改变音调n个半音（n = -60.0 .. + 60.0半音）
     -rate = n 将声音播放率更改为n个百分点（n = -95.0 .. +5000.0％）
     -bpm = n 检测声音的每分钟节拍（BPM）速率，并调整速度以满足“ n”个BPM。当应用此开关时，将忽略“ -tempo”开关。如果省略“ = n”，即单独使用开关“ -bpm”，则将估算并显示BPM速率，但速度不会根据BPM值进行调整。
     */
    
    //采样率 <这里使用8000 原因: 录音是采样率:8000>
    _st.setSampleRate(self.audioFormat.mSampleRate);
    //设置声音的声道
    _st.setChannels(self.audioFormat.mChannelsPerFrame);
    //速度 <变速不变调>，取值范围：-50 ～ 100
    _st.setTempoChange(self.tempo);
    //设置声音的pitch，取值范围：-12 ～ 12； (集音高变化semi-tones相比原来的音调) //男: -8 女:8
    _st.setPitchSemiTones(self.pitchSemiTones);
    //设置声音的速率，取值范围：-50 ～ 100
    _st.setRateChange(self.rateChange);
    _st.setSetting(SETTING_SEQUENCE_MS, 40);
    //寻找帧长
    _st.setSetting(SETTING_SEEKWINDOW_MS, 15);
    //重叠帧长
    _st.setSetting(SETTING_OVERLAP_MS, 6);
    
    NSString *filePath = self.filePath;
    //建立文件
    _file = fopen(filePath.UTF8String, "wb+");
    if (_file == NULL) {
        return NO;
    }
    
    return YES;
}

- (void)closeAudioFile
{
    //函数fseek & ftell 组合计算流的长度
    fseek(_file, 0, SEEK_END);
    int fileLength = (int)ftell(_file);
    void *wavHeader = CCDCreateWaveHeader(fileLength,
                                       self.audioFormat.mChannelsPerFrame,
                                       self.audioFormat.mSampleRate,
                                       self.audioFormat.mBitsPerChannel);
    
    /**
     在头部插入 wav 文件头
     SEEK_SET：0-文件开头；SEEK_CUR：1-文件当前位置；SEEK_END：2-文件结尾
     */
    fseek(_file, 0, SEEK_SET);
    fwrite(wavHeader, 1, sizeof(CCDAudioWaveHeader), _file);
    
    if (wavHeader) {
        free(wavHeader);
        wavHeader = NULL;
    }
    
    if (_file) {
        fclose(_file);
        _file = NULL;
    }
}

#pragma mark - CCDAudioQueueRecorderOutput

- (void)receiveAudio:(const void *)aAudioData size:(UInt32)aSize
{
    short *audioData = (short *)aAudioData;
    UInt32 pcmLen = aSize;
    if (pcmLen < 2) {
        return;
    }
    
    // audioData -> samples -> file
    int nsamples = pcmLen / 2;
    _st.putSamples((short *)audioData, nsamples);
    short *samples = new short[pcmLen];
    int numSamples = 0;
    do {
        memset(samples, 0, pcmLen);
        numSamples = _st.receiveSamples(samples, pcmLen);
        fwrite(samples, 1, numSamples * 2, _file);
    } while (numSamples > 0);
    delete [] samples;
}

- (void)copyEncoderCookieToFile:(AudioQueueRef)inAQ error:(NSError **)error
{}

@end
