//
//  CCDAudioRecorderOutputAAC.m
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/18.
//

#import "CCDAudioRecorderOutputAAC.h"

@interface CCDAudioRecorderOutputAAC ()
{
    char *_leftBuffer; // 待编码缓冲区
    NSInteger _leftLength; // 待编码缓冲区的长度，动态
}

/// 音频编码器实例
@property (nonatomic, assign) AudioConverterRef audioConverter;
@property (nonatomic, assign) uint8_t *aacBuffer;
@property (nonatomic, assign) NSInteger aacBufferSize;

@property (nonatomic, assign) char *pcmBuffer;
@property (nonatomic, assign) size_t pcmBufferSize;

/// 音频编码参数
@property (nonatomic, assign) CMFormatDescriptionRef aacFormat;
/// 音频编码码率
@property (nonatomic, assign) NSInteger audioBitrate;

@property (nonatomic, strong) NSOutputStream *outputStream;

@end

@implementation CCDAudioRecorderOutputAAC

@synthesize audioPath = _audioPath;
@synthesize audioFormat = _audioFormat;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _audioPath = [NSTemporaryDirectory() stringByAppendingString:@"record.aac"];
        _audioBitrate = 44100;
        [self setupAudioFormat:44100];
        
        _aacBufferSize = 1024;
        _aacBuffer = malloc(_aacBufferSize * sizeof(uint8_t));
        memset(_aacBuffer, 0, _aacBufferSize);
        [self setupOutputAudioFormat:_audioFormat];
    }
    return self;
}

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

- (void)setupOutputAudioFormat:(AudioStreamBasicDescription)inputFormat
{
    // 设置音频编码器输出参数。其中一些参数与输入的音频数据参数一致。
    AudioStreamBasicDescription outputFormat = {0};
    outputFormat.mSampleRate = inputFormat.mSampleRate; // 输出采样率与输入一致。
    outputFormat.mFormatID = kAudioFormatMPEG4AAC; // AAC 编码格式。常用的 AAC 编码格式：kAudioFormatMPEG4AAC、kAudioFormatMPEG4AAC_HE_V2。
    outputFormat.mFormatFlags = kMPEG4Object_AAC_LC; // 无损编码 ，0表示没有
    outputFormat.mChannelsPerFrame = (UInt32) inputFormat.mChannelsPerFrame; // 输出声道数与输入一致。
    outputFormat.mFramesPerPacket = 1024; // 每个包的帧数。AAC 固定是 1024，这个是由 AAC 编码规范规定的。对于未压缩数据设置为 1。
    outputFormat.mBytesPerPacket = 0; // 每个包的大小。动态大小设置为 0。
    outputFormat.mBytesPerFrame = 0; // 每帧的大小。压缩格式设置为 0。
    outputFormat.mBitsPerChannel = 0; // 压缩格式设置为 0。
    
    AudioClassDescription *description = [self audioClassDescriptionWithType:kAudioFormatMPEG4AAC fromManufacturer:kAppleHardwareAudioCodecManufacturer];
    // 基于音频输入和输出参数创建音频编码器
    OSStatus status = AudioConverterNewSpecific(&inputFormat, &outputFormat, 1, description, &_audioConverter);
    if (status != noErr) {
        CCDAudioLogE(@"AudioConverterNewSpecific: %@", @(status));
        return;
    }
}

/**
 *  获取编解码器
 *
 *  @param type         编码格式
 *  @param manufacturer 软/硬编
 *
 编解码器（codec）指的是一个能够对一个信号或者一个数据流进行变换的设备或者程序。这里指的变换既包括将 信号或者数据流进行编码（通常是为了传输、存储或者加密）或者提取得到一个编码流的操作，也包括为了观察或者处理从这个编码流中恢复适合观察或操作的形式的操作。编解码器经常用在视频会议和流媒体等应用中。
 *  @return 指定编码器
 */
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

- (NSOutputStream *)outputStream
{
    if (nil == _outputStream) {
        _outputStream = [[NSOutputStream alloc] initToFileAtPath:_audioPath append:NO];
    }
    return _outputStream;
}

#pragma mark - CCDAudioRecorderDataOutput

- (void)begin
{
    [self.outputStream open];
}

- (void)end
{
    [self.outputStream close];
}

- (void)write:(AudioBufferList *)bufferList
{
    NSInteger pcmDataSize = bufferList->mBuffers[0].mDataByteSize;
    void *pcmData = malloc(pcmDataSize);
    memset(pcmData, 0, pcmDataSize);
    memcpy(pcmData, bufferList->mBuffers[0].mData, pcmDataSize);

    _pcmBuffer = pcmData;
    _pcmBufferSize = pcmDataSize;

    AudioBufferList inBufferList = {0};
    inBufferList.mNumberBuffers = 1;
    inBufferList.mBuffers[0].mNumberChannels = 1;
    inBufferList.mBuffers[0].mDataByteSize = bufferList->mBuffers[0].mDataByteSize;
    inBufferList.mBuffers[0].mData = bufferList->mBuffers[0].mData;
    
//    AudioBufferList *inBufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList));
//    inBufferList->mNumberBuffers = 1;
//    inBufferList->mBuffers[0].mNumberChannels = 1;
//    inBufferList->mBuffers[0].mDataByteSize = bufferList->mBuffers[0].mDataByteSize;
//    inBufferList->mBuffers[0].mData = bufferList->mBuffers[0].mData;
    
    memset(_aacBuffer, 0, _aacBufferSize);
    
    // 1.创建编码输出缓冲区 AudioBufferList 接收编码后的数据
    AudioBufferList outBufferList = {0};
    outBufferList.mNumberBuffers = 1;
    outBufferList.mBuffers[0].mNumberChannels = 1;
    outBufferList.mBuffers[0].mDataByteSize = (UInt32)_aacBufferSize;
    outBufferList.mBuffers[0].mData = _aacBuffer;
    
    // 2.编码
    /// 每次编码 1 个包。1 个包有 1024 个帧，这个对应创建编码器实例时设置的 mFramesPerPacket。
    UInt32 outputDataPacketSize = 1;
    /// 需要在回调方法 inputDataProcess 中将待编码的数据拷贝到编码器的缓冲区的对应位置。
    /// 这里把我们自己创建的待编码缓冲区 AudioBufferList 作为 inInputDataProcUserData 传入，
    /// 在回调方法中直接拷贝它。
    OSStatus status = AudioConverterFillComplexBuffer(_audioConverter, inputDataProcess, &inBufferList, &outputDataPacketSize, &outBufferList, NULL);
//    OSStatus status = AudioConverterFillComplexBuffer(_audioConverter, inputDataProcess, inBufferList, &outputDataPacketSize, &outBufferList, NULL);
//    OSStatus status = AudioConverterFillComplexBuffer(_audioConverter, inputDataProcess, (__bridge void *)(self), &outputDataPacketSize, &outBufferList, NULL);
    if (status != noErr) {
        CCDAudioLogE(@"AudioConverterFillComplexBuffer: %@", @(status));
        return;
    }
    
    if (outputDataPacketSize == 0) {
        return;
    }
    
    // 3.获取编码后的 AAC 数据并进行封装
    size_t aacEncoderSize = outBufferList.mBuffers[0].mDataByteSize;
    char *aacEncoderBufferData = malloc(aacEncoderSize);
    memcpy(aacEncoderBufferData, outBufferList.mBuffers[0].mData, aacEncoderSize);
    
    NSData *headerData = [self adtsDataForPacketLength:aacEncoderSize];
    [self write:(void *)headerData.bytes maxSize:7];
    [self write:aacEncoderBufferData maxSize:aacEncoderSize];
}

- (void)write:(void *)bytes maxSize:(NSInteger)maxSize
{
#ifdef DEBUG1
    CCDAudioLogD(@"write size: %@", @(maxSize));
    NSData *bufferData = [NSData dataWithBytes:bytes length:maxSize];
    CCDAudioLogD(@"buffer data: %@", bufferData);
#endif
    
    [self.outputStream write:bytes maxLength:maxSize];
}

#pragma mark -

/**
 *  填充PCM到缓冲区
 */
- (size_t)copyPCMSamplesIntoBuffer:(AudioBufferList *)ioData
{
    size_t originalBufferSize = _pcmBufferSize;
    if (!originalBufferSize) {
        return 0;
    }
    ioData->mBuffers[0].mData = _pcmBuffer;
    ioData->mBuffers[0].mDataByteSize = (int)_pcmBufferSize;
    
    if (_pcmBuffer) {
        free(_pcmBuffer);
        _pcmBuffer = NULL;
    }
    _pcmBufferSize = 0;
    return originalBufferSize;
}

#pragma mark - 拼接ADTS头
/**
 *  Add ADTS header at the beginning of each and every AAC packet.
 *  This is needed as MediaCodec encoder generates a packet of raw
 *  AAC data.
 *
 *  Note the packetLen must count in the ADTS header itself.
 *  See: http://wiki.multimedia.cx/index.php?title=ADTS
 *  Also: http://wiki.multimedia.cx/index.php?title=MPEG-4_Audio#Channel_Configurations
 **/
- (NSData*)adtsDataForPacketLength:(NSUInteger)packetLength
{
    int adtsLength = 7;
    char *packet = malloc(sizeof(char) * adtsLength);
    // Variables Recycled by addADTStoPacket
    int profile = 2;  //AAC LC
    //39=MediaCodecInfo.CodecProfileLevel.AACObjectELD;
    int freqIdx = 4;  //44.1KHz
    int chanCfg = 1;  //MPEG-4 Audio Channel Configuration. 1 Channel front-center
    NSUInteger fullLength = adtsLength + packetLength;
    // fill in ADTS data
    packet[0] = (char)0xFF; // 11111111     = syncword
    packet[1] = (char)0xF9; // 1111 1 00 1  = syncword MPEG-2 Layer CRC
    packet[2] = (char)(((profile-1)<<6) + (freqIdx<<2) +(chanCfg>>2));
    packet[3] = (char)(((chanCfg&3)<<6) + (fullLength>>11));
    packet[4] = (char)((fullLength&0x7FF) >> 3);
    packet[5] = (char)(((fullLength&7)<<5) + 0x1F);
    packet[6] = (char)0xFC;
    NSData *data = [NSData dataWithBytesNoCopy:packet length:adtsLength freeWhenDone:YES];
    return data;
}

#pragma mark - Encoder CallBack

static OSStatus inputDataProcess(AudioConverterRef inConverter,
                                 UInt32 *ioNumberDataPackets,
                                 AudioBufferList *ioData,
                                 AudioStreamPacketDescription **outDataPacketDescription,
                                 void *inUserData) {
//    CCDAudioRecorderOutputAAC *encoder = (__bridge CCDAudioRecorderOutputAAC *)(inUserData);
//    UInt32 requestedPackets = *ioNumberDataPackets;
//
//    size_t copiedSamples = [encoder copyPCMSamplesIntoBuffer:ioData];
//    if (copiedSamples < requestedPackets) {
//        //PCM 缓冲区还没满
//        *ioNumberDataPackets = 0;
//        return -1;
//    }
    
    // 将待编码的数据拷贝到编码器的缓冲区的对应位置进行编码。
    AudioBufferList *bufferList = inUserData;
    if (bufferList->mBuffers[0].mDataByteSize == 0) {
        *ioNumberDataPackets = 0;
        return -1;
    }
    ioData->mBuffers[0].mData = bufferList->mBuffers[0].mData;
    ioData->mBuffers[0].mDataByteSize = bufferList->mBuffers[0].mDataByteSize;
    // 清理数据，不清理会出现录制的音频出现延迟；why？？？
    bufferList->mBuffers[0].mData = NULL;
    bufferList->mBuffers[0].mDataByteSize = 0;
    
    *ioNumberDataPackets = 1;
    return noErr;
}

@end
