//
//  CCDAQAudioRecorderMP3Output.m
//  Cicada
//
//  Created by ruhong zhu on 2020/6/20.
//

#import "CCDAQAudioRecorderMP3Output.h"
#import "lame.h"

@interface CCDAQAudioRecorderMP3Output ()
{
    FILE *_file;
    lame_t _lame;
}

@end

@implementation CCDAQAudioRecorderMP3Output

//@synthesize audioType;
@synthesize audioFormat;
@synthesize filePath;

- (instancetype)init
{
    self = [super init];
    if (self) {
//        self.audioType = CCDAudioTypeMP3;
        
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
        self.audioFormat = tempAudioFormat;
        
        NSString *name = [NSString stringWithFormat:@"audio_output.mp3"];
        self.filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
    }
    return self;
}

#pragma mark - CCDAudioRecorderOutput

- (BOOL)openAudioFile
{
    NSString *filePath = self.filePath;
    
    //mp3压缩参数
    _lame = lame_init();
    lame_set_num_channels(_lame, 1);
    lame_set_in_samplerate(_lame, 8000);
    lame_set_out_samplerate(_lame, 8000);
    lame_set_brate(_lame, 128);
    lame_set_mode(_lame, JOINT_STEREO);
    lame_set_quality(_lame, 2);
    lame_init_params(_lame);
    
    //建立mp3文件
    _file = fopen(filePath.UTF8String, "wb+");
    if (_file == NULL) {
        return NO;
    }
    
    return YES;
}

- (void)closeAudioFile
{
    if (_file) {
        fclose(_file);
        _file = NULL;
    }
    
    if (_lame) {
        lame_close(_lame);
        _lame = NULL;
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
    
    int nsamples = pcmLen / 2;
    unsigned char buffer[pcmLen];
    //mp3 encode
    int recvLen = lame_encode_buffer(_lame, audioData, audioData, nsamples, buffer, pcmLen);
    if (fwrite(buffer, 1, recvLen, _file) == 0) {
        return;
    }
}

- (void)copyEncoderCookieToFile:(AudioQueueRef)inAQ error:(NSError **)error
{}

@end
