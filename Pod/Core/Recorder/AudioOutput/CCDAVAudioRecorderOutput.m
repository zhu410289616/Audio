//
//  CCDAVAudioRecorderOutput.m
//  Cicada
//
//  Created by ruhong zhu on 2020/6/14.
//

#import "CCDAVAudioRecorderOutput.h"

@implementation CCDAVAudioRecorderOutput

@synthesize audioPath = _audioPath;
@synthesize audioFormat = _audioFormat;

+ (instancetype)m4aAudioOutput
{
    id<CCDAudioRecorderDataOutput> audioOutput = [[self alloc] init];
    
    AudioStreamBasicDescription tempAudioFormat;
    memset(&tempAudioFormat, 0, sizeof(tempAudioFormat));
    // 设置formatID
    tempAudioFormat.mFormatID = kAudioFormatMPEG4AAC;
    // 采样率的意思是每秒需要采集的帧数 [AVAudioSession sharedInstance].sampleRate;
    tempAudioFormat.mSampleRate = 16000;
    // 设置通道数 (UInt32)[AVAudioSession sharedInstance].inputNumberOfChannels;
    tempAudioFormat.mChannelsPerFrame = 1;
    
    NSString *name = [NSString stringWithFormat:@"audio_output.m4a"];
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
    
    audioOutput.audioFormat = tempAudioFormat;
    audioOutput.audioPath = filePath;
    return audioOutput;
}

+ (instancetype)cafAudioOutput
{
    id<CCDAudioRecorderDataOutput> audioOutput = [[self alloc] init];
    
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
    
    NSString *name = [NSString stringWithFormat:@"audio_output.m4a"];
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
    
    audioOutput.audioFormat = tempAudioFormat;
    audioOutput.audioPath = filePath;
    return audioOutput;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    AudioStreamBasicDescription tempAudioFormat;
    memset(&tempAudioFormat, 0, sizeof(tempAudioFormat));
    tempAudioFormat.mFormatID = kAudioFormatMPEG4AAC;
    tempAudioFormat.mSampleRate = 16000;
    tempAudioFormat.mChannelsPerFrame = 1;
    self.audioFormat = tempAudioFormat;
}

- (NSString *)audioPath
{
    if (nil == _audioPath) {
        NSString *filename = [NSString stringWithFormat:@"%@", @"audio.m4a"];
        _audioPath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    }
    return _audioPath;
}

#pragma mark - CCDAudioRecorderDataOutput

- (void)begin
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:self.audioPath]) {
        [fileManager removeItemAtPath:self.audioPath error:nil];
    }
    [fileManager createFileAtPath:self.audioPath contents:nil attributes:nil];
}

- (void)end {}

- (void)write:(nonnull AudioBufferList *)bufferList {}

@end
