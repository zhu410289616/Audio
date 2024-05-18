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
    audioFormat.mFormatID = kAudioFormatLinearPCM; //音频格式

    //详细描述了音频数据的数字格式，整数还是浮点数，大端还是小端
    //注意，如果是双声道，这里一定要设置kAudioFormatFlagIsNonInterleaved，否则初始化AudioUnit会出现错误 1718449215
    //kAudioFormatFlagIsNonInterleaved，非交错模式，即首先记录的是一个周期内所有帧的左声道样本，再记录所有右声道样本。
    //对应的认为交错模式，数据以连续帧的方式存放，即首先记录帧1的左声道样本和右声道样本，再开始帧2的记录。
    audioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsNonInterleaved;

    //下面就是设置声音采集时的一些值
    //比如采样率为44.1kHZ，采样精度为16位的双声道，可以算出比特率（bps）是44100*16*2bps，每秒的音频数据是固定的44100*16*2/8字节。
    //官方解释：满足下面这个公式时，上面的mFormatFlags会隐式设置为kAudioFormatFlagIsPacked
    //((mBitsPerSample / 8) * mChannelsPerFrame) == mBytesPerFrame
    audioFormat.mBytesPerPacket = 2;
    audioFormat.mFramesPerPacket = 1;
    audioFormat.mBytesPerFrame = 2;
    audioFormat.mChannelsPerFrame = 1;//1是单声道，2就是立体声。这里的数量决定了AudioBufferList的mBuffers长度是1还是2。
    audioFormat.mBitsPerChannel = 16;//采样位数，数字越大，分辨率越高。16位可以记录65536个数，一般来说够用了。

    self.audioFormat = audioFormat;
}

#pragma mark - CCDAudioRecorderDataOutput

- (void)begin
{
    // 写入文件的数据格式
    AudioStreamBasicDescription fileDataDesc = {0};
    fileDataDesc.mSampleRate = self.audioFormat.mSampleRate;
    fileDataDesc.mFormatID = kAudioFormatMPEG4AAC; //音频格式
    fileDataDesc.mFormatFlags = kMPEG4Object_AAC_Main;
    fileDataDesc.mFramesPerPacket = 1024;
    fileDataDesc.mChannelsPerFrame = self.audioFormat.mChannelsPerFrame;
    fileDataDesc.mBytesPerFrame = 0;// 这些填0就好，内部编码算法会自己计算
    fileDataDesc.mBytesPerPacket = 0;// 这些填0就好，内部编码算法会自己计算
    fileDataDesc.mBitsPerChannel = 0;// 这些填0就好，内部编码算法会自己计算
    fileDataDesc.mReserved = 0;
    
    NSURL *fileURL = [NSURL fileURLWithPath:self.audioPath];
    OSStatus status = ExtAudioFileCreateWithURL((__bridge CFURLRef _Nonnull)(fileURL), kAudioFileM4AType, &fileDataDesc, NULL, kAudioFileFlags_EraseFile, &_audioFile);
    if (status != noErr) {
        CCDAudioLogE(@"ExtAudioFileCreateWithURL: %@", @(status));
        return;
    }
    
    // 指定是硬件编码还是软件编码
    UInt32 codec = kAppleSoftwareAudioCodecManufacturer;
    status = ExtAudioFileSetProperty(_audioFile, kExtAudioFileProperty_CodecManufacturer, sizeof(codec), &codec);
    if (status != noErr) {
        CCDAudioLogE(@"kExtAudioFileProperty_CodecManufacturer: %@", @(status));
        return;
    }
    
    /** 遇到问题：返回1718449215错误；
     *  解决方案：
     *  _audioFormat格式不正确，比如ASDB中mFormatFlags与所对应的mBytesPerPacket等等不符合，那么会造成这种错误
     */
    // 指定输入给ExtAudioUnitRef的音频PCM数据格式(必须要有)
    status = ExtAudioFileSetProperty(_audioFile, kExtAudioFileProperty_ClientDataFormat, sizeof(_audioFormat), &_audioFormat);
    if (status != noErr) {
        CCDAudioLogE(@"kExtAudioFileProperty_ClientDataFormat: %@", @(status));
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
    status = ExtAudioFileWrite(_audioFile, (UInt32)channels, bufferList);
    if (status != noErr) {
        CCDAudioLogE(@"ExtAudioFileWrite: %@", @(status));
        return;
    }
}


@end
