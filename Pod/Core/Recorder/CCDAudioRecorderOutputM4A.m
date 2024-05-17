//
//  CCDAudioRecorderOutputM4A.m
//  CCDAudio
//
//  Created by zhuruhong on 2024/5/17.
//

#import "CCDAudioRecorderOutputM4A.h"

@interface CCDAudioRecorderOutputM4A ()
{
    ExtAudioFileRef _audioFile;
}

@end

@implementation CCDAudioRecorderOutputM4A

@synthesize audioPath = _audioPath;
@synthesize audioFormat = _audioFormat;

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *name = [NSString stringWithFormat:@"audio_output.m4a"];
        self.audioPath = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
        [self setupAudioFormat:44100];
    }
    return self;
}

#pragma mark -

- (void)setupAudioFormat:(NSInteger)sampleRate
{
    AudioStreamBasicDescription audioFormat;
    //采样率，每秒钟抽取声音样本次数。根据奈奎斯特采样理论，为了保证声音不失真，采样频率应该在40kHz左右
    audioFormat.mSampleRate = sampleRate;
    audioFormat.mFormatID = kAudioFormatMPEG4AAC; //音频格式
    audioFormat.mFormatFlags = kMPEG4Object_AAC_Main;
    audioFormat.mFramesPerPacket = 1024;
    //1是单声道，2就是立体声。这里的数量决定了AudioBufferList的mBuffers长度是1还是2。
    audioFormat.mChannelsPerFrame = 1;
    audioFormat.mBytesPerFrame = 0;// 这些填0就好，内部编码算法会自己计算
    audioFormat.mBytesPerPacket = 0;// 这些填0就好，内部编码算法会自己计算
    audioFormat.mBitsPerChannel = 0;// 这些填0就好，内部编码算法会自己计算
    audioFormat.mReserved = 0;
    self.audioFormat = audioFormat;
}

#pragma mark - CCDAudioRecorderDataOutput

- (void)begin
{
    NSURL *fileURL = [NSURL fileURLWithPath:self.audioPath];
    OSStatus status = ExtAudioFileCreateWithURL((__bridge CFURLRef _Nonnull)(fileURL), kAudioFileM4AType, &_audioFormat, NULL, kAudioFileFlags_EraseFile, &_audioFile);
    
    // 指定是硬件编码还是软件编码
    UInt32 codec = kAppleSoftwareAudioCodecManufacturer;
    status = ExtAudioFileSetProperty(_audioFile, kExtAudioFileProperty_CodecManufacturer, sizeof(codec), &codec);
    if (status != noErr) {
        NSLog(@"ExtAudioFileSetProperty kExtAudioFileProperty_CodecManufacturer fail %d",status);
        return;
    }
    
    /** 遇到问题：返回1718449215错误；
     *  解决方案：_clientabsdForWriter格式不正确，比如ASDB中mFormatFlags与所对应的mBytesPerPacket等等不符合，那么会造成这种错误
     */
    // 指定输入给ExtAudioUnitRef的音频PCM数据格式(必须要有)
    status = ExtAudioFileSetProperty(_audioFile, kExtAudioFileProperty_ClientDataFormat, sizeof(_audioFormat), &_audioFormat);
    if (status != noErr) {
        NSLog(@"ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat fail %d",status);
        return;
    }
}

- (void)end
{
    if (_audioFile) {
        ExtAudioFileDispose(_audioFile);
        _audioFile = nil;
    }
}

- (void)write:(AudioBufferList *)bufferList
{
    NSInteger channels = bufferList->mNumberBuffers;
    OSStatus status = noErr;
    status = ExtAudioFileWriteAsync(_audioFile, (UInt32)channels, bufferList);
}


@end
