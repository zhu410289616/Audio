//
//  CCDAQAudioRecorderAMROutput.m
//  Cicada
//
//  Created by ruhong zhu on 2020/6/20.
//

#import "CCDAQAudioRecorderAMROutput.h"
#import "interf_enc.h"

@interface CCDAQAudioRecorderAMROutput ()
{
    FILE *_file;
    void *_destate;
}

@end

@implementation CCDAQAudioRecorderAMROutput

//@synthesize audioType;
@synthesize audioFormat;
@synthesize filePath;

- (instancetype)init
{
    self = [super init];
    if (self) {
//        self.audioType = CCDAudioTypeAMR;
        
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
        
        NSString *name = [NSString stringWithFormat:@"audio_output.amr"];
        self.filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
    }
    return self;
}

#pragma mark - CCDAudioRecorderOutput

- (BOOL)openAudioFile
{
    NSString *filePath = self.filePath;
    
    _destate = NULL;
    //amr压缩句柄
    _destate = Encoder_Interface_init(0);
    if (NULL == _destate) {
        return NO;
    }
    
    //建立amr文件
    _file = fopen(filePath.UTF8String, "wb+");
    if (_file == NULL) {
        return NO;
    }
    
    //写入文件头
    static const char *amrHeader = "#!AMR\n";
    if (fwrite(amrHeader, 1, strlen(amrHeader), _file) == 0) {
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
    
    if (_destate) {
        Encoder_Interface_exit(_destate);
        _destate = NULL;
    }
}

#pragma mark - CCDAudioQueueRecorderOutput

- (void)receiveAudio:(const void *)aAudioData size:(UInt32)aSize
{
    short *audioData = (short *)aAudioData;
    UInt32 pcmLen = aSize;
    if (pcmLen <= 0) {
        return;
    }
    
    if (pcmLen % 2 != 0) {
        pcmLen--;//防止意外，如果不是偶数，情愿减去最后一个字节。
    }
    
    unsigned char buffer[320];
    for (int i=0; i<pcmLen; i+=160*2) {
        short *pPacket = (short *)((unsigned char *)audioData+i);
        if (pcmLen-i < 160*2) {
            continue;//不是一个完整的就拜拜
        }
        
        memset(buffer, 0, sizeof(buffer));
        //encode
        int recvLen = Encoder_Interface_Encode(_destate, MR515, pPacket, buffer, 0);
        if (fwrite(buffer, 1, recvLen, _file) == 0) {
            return;
        }
    }
}

- (void)copyEncoderCookieToFile:(AudioQueueRef)inAQ error:(NSError **)error
{}

@end
