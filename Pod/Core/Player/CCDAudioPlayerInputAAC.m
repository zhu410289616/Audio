//
//  CCDAudioPlayerInputAAC.m
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/20.
//

#import "CCDAudioPlayerInputAAC.h"

const static NSInteger OUTPUT_BUS = 0;
const static NSInteger CONST_BUFFER_SIZE = 5000;
const static NSInteger NO_MORE_DATA = -100000;

@interface CCDAudioPlayerInputAAC ()

@property (nonatomic, strong) NSURL *audioURL;
@property (nonatomic, assign) AudioConverterRef audioConverter;
@property (assign, nonatomic) AudioStreamBasicDescription srcAudioFormat;
//获取格式，转码需要的属性
@property (assign, nonatomic) AudioFileID audioFileID;
@property (assign, nonatomic) AudioStreamPacketDescription *packetFormat;
@property (assign, nonatomic) SInt64 startingPacket;
@property (assign, nonatomic) Byte *convertBuffer;
@property (assign, nonatomic) AudioBufferList *bufferList;

@end

@implementation CCDAudioPlayerInputAAC

@synthesize audioPath = _audioPath;
@synthesize audioFormat = _audioFormat;

- (instancetype)initWithURL:(NSURL *)audioURL
{
    if (self = [super init]) {
        _audioURL = audioURL;
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
    audioFormat.mFormatID = kAudioFormatLinearPCM;
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
    [self setupInputAudioFormat:audioFormat];
}

- (void)setupInputAudioFormat:(AudioStreamBasicDescription)outputFormat
{
    AudioStreamBasicDescription inputFormat = {0};
    inputFormat.mSampleRate = outputFormat.mSampleRate; // 输出采样率与输入一致。
    inputFormat.mFormatID = kAudioFormatMPEG4AAC; // AAC 编码格式。常用的 AAC 编码格式：kAudioFormatMPEG4AAC、kAudioFormatMPEG4AAC_HE_V2。
    inputFormat.mFormatFlags = kMPEG4Object_AAC_Main;
    inputFormat.mChannelsPerFrame = (UInt32) outputFormat.mChannelsPerFrame; // 输出声道数与输入一致。
    inputFormat.mFramesPerPacket = 1024; // 每个包的帧数。AAC 固定是 1024，这个是由 AAC 编码规范规定的。对于未压缩数据设置为 1。
    inputFormat.mBytesPerPacket = 0; // 每个包的大小。动态大小设置为 0。
    inputFormat.mBytesPerFrame = 0; // 每帧的大小。压缩格式设置为 0。
    inputFormat.mBitsPerChannel = 0; // 压缩格式设置为 0。
    
    self.srcAudioFormat = inputFormat;
}

- (AudioClassDescription *)audioClassDescriptionWithType:(AudioFormatID)type fromManufacturer:(UInt32)manufacturer
{
    static AudioClassDescription desc;
    
    UInt32 encoderSpecifier = type;
    OSStatus status = noErr;
    
    UInt32 size;
    status = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size);
    if (status) {
        CCDAudioLogE(@"AudioFormatGetPropertyInfo: %@", @(status));
        return nil;
    }
    
    unsigned int count = size / sizeof(AudioClassDescription);
    AudioClassDescription descriptions[count];
    status = AudioFormatGetProperty(kAudioFormatProperty_Encoders, sizeof(encoderSpecifier), &encoderSpecifier, &size, descriptions);
    if (status) {
        CCDAudioLogE(@"AudioFormatGetProperty: %@", @(status));
        return nil;
    }
    
    for (unsigned int i = 0; i < count; i++) {
        if ((type == descriptions[i].mSubType) &&
            (manufacturer == descriptions[i].mManufacturer)) {
            memcpy(&desc, &(descriptions[i]), sizeof(desc));
            return &desc;
        }
    }
    return nil;
}

#pragma mark - getter & setter

#pragma mark - CCDAudioPlayerDataInput

- (void)begin
{
    OSStatus status = AudioFileOpenURL((__bridge CFURLRef)_audioURL, kAudioFileReadPermission, 0, &_audioFileID);
    if (status) {
        CCDAudioLogE(@"AudioFileOpenURL: %@", @(status));
    } else {
        uint32_t size = sizeof(AudioStreamBasicDescription);
        status = AudioFileGetProperty(_audioFileID, kAudioFilePropertyDataFormat, &size, &(_srcAudioFormat));
        if (status) {
            CCDAudioLogE(@"AudioFileOpenURL: %@", @(status));
        }
    }
    
    self.packetFormat = malloc(sizeof(AudioStreamPacketDescription));
    self.startingPacket = 0;
    self.convertBuffer = malloc(CONST_BUFFER_SIZE * 2);
    
    AudioClassDescription *description = [self audioClassDescriptionWithType:kAudioFormatMPEG4AAC fromManufacturer:kAppleHardwareAudioCodecManufacturer];
    // 基于音频输入和输出参数创建音频编码器
    status = AudioConverterNewSpecific(&_srcAudioFormat, &_audioFormat, 1, description, &_audioConverter);
    if (status != noErr) {
        CCDAudioLogE(@"AudioConverterNewSpecific: %@", @(status));
        return;
    }
}

- (void)end
{
}

- (void)read:(CCDAudioPlayerInCallback)callback maxSize:(NSInteger)maxSize
{
    AudioBufferList inBufferList = {0};
    inBufferList.mNumberBuffers = 1;
    inBufferList.mBuffers[0].mNumberChannels = 1;
//    inBufferList.mBuffers[0].mDataByteSize = CONST_BUFFER_SIZE;
//    inBufferList.mBuffers[0].mData = malloc(CONST_BUFFER_SIZE);
    
    AudioBufferList *outBufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList));
    outBufferList->mNumberBuffers = 1;
    outBufferList->mBuffers[0].mNumberChannels = 1;
    outBufferList->mBuffers[0].mDataByteSize = CONST_BUFFER_SIZE;
    outBufferList->mBuffers[0].mData = malloc(CONST_BUFFER_SIZE);
    
    UInt32 outputDataPacketSize = 1;
    OSStatus status = AudioConverterFillComplexBuffer(_audioConverter, InputAudioDataProc, (__bridge void *)(self), &outputDataPacketSize, outBufferList, NULL);
    if (status != noErr) {
        CCDAudioLogE(@"AudioConverterFillComplexBuffer: %@", @(status));
        !callback ?: callback(NULL, 0);
        return;
    }
    
    
#ifdef DEBUG1
    CCDAudioLogD(@"read size: %@", @(readSize));
    NSData *bufferData = [NSData dataWithBytes:buffer length:readSize];
    CCDAudioLogD(@"buffer data: %@", bufferData);
#endif
    
    !callback ?: callback(outBufferList->mBuffers[0].mData, outBufferList->mBuffers[0].mDataByteSize);
    
    outBufferList->mBuffers[0].mDataByteSize = 0;
    outBufferList->mBuffers[0].mData = NULL;
}

#pragma mark -

//读取本地的音频格式的数据，然后通过ioData输出，外面拿到的就是转换好的PCM格式数据
static OSStatus InputAudioDataProc(AudioConverterRef inAudioConverter,
                                 UInt32 *ioNumberDataPackets,
                                 AudioBufferList *ioData,
                                 AudioStreamPacketDescription **outDataPacketDescription,
                                 void *inUserData) {
    CCDAudioPlayerInputAAC *player = (__bridge  CCDAudioPlayerInputAAC *)(inUserData);
    UInt32 byteSize = CONST_BUFFER_SIZE;
    OSStatus status = AudioFileReadPacketData(player.audioFileID, NO, &byteSize, player.packetFormat, player.startingPacket, ioNumberDataPackets, player.convertBuffer);
    if (status != noErr) {
        CCDAudioLogE(@"AudioFileReadPacketData: %@", @(status));
        return status;
    }
    if (outDataPacketDescription) {
        *outDataPacketDescription = player.packetFormat;
    }

    NSLog(@"MP3InputDataProc %u", byteSize);

    if (!status && ioNumberDataPackets > 0) {
        ioData->mBuffers[0].mDataByteSize = byteSize;
        ioData->mBuffers[0].mData = player.convertBuffer;
        player.startingPacket += *ioNumberDataPackets;
        return noErr;
    } else {
        return NO_MORE_DATA;
    }

    return noErr;
}

@end
