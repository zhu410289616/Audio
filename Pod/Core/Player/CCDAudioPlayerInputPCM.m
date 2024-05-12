//
//  CCDAudioPlayerInputPCM.m
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/12.
//

#import "CCDAudioPlayerInputPCM.h"

@interface CCDAudioPlayerInputPCM ()

@property (nonatomic, strong) NSInputStream *inputStream;

@end

@implementation CCDAudioPlayerInputPCM

@synthesize audioPath = _audioPath;
@synthesize audioFormat = _audioFormat;

- (instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        _audioPath = path;
        _inputStream = [[NSInputStream alloc] initWithFileAtPath:path];
        [self setupAudioFormat];
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)audioURL
{
    if (self = [super init]) {
        _inputStream = [[NSInputStream alloc] initWithURL:audioURL];
        [self setupAudioFormat];
    }
    return self;
}

#pragma mark -

- (void)setupAudioFormat
{
    AudioStreamBasicDescription audioFormat;
    //采样率，每秒钟抽取声音样本次数。根据奈奎斯特采样理论，为了保证声音不失真，采样频率应该在40kHz左右
    audioFormat.mSampleRate = 16000;
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

#pragma mark - getter & setter

- (NSInputStream *)inputStream
{
    if (nil == _inputStream) {
        _inputStream = [[NSInputStream alloc] initWithFileAtPath:self.audioPath];
    }
    return _inputStream;
}

#pragma mark - CCDAudioPlayerDataInput

- (void)begin
{
    [self.inputStream open];
}

- (void)end
{
    [self.inputStream close];
}

- (void)read:(CCDAudioDataCallback)callback maxSize:(NSInteger)maxSize
{
    void *buffer = malloc(maxSize);
    NSInteger readSize = [self.inputStream read:buffer maxLength:maxSize];
    
#ifdef DEBUG
//    CCDAudioLogD(@"read size: %@", @(readSize));
//    NSData *bufferData = [NSData dataWithBytes:buffer length:readSize];
//    CCDAudioLogD(@"buffer data: %@", bufferData);
#endif
    
    !callback ?: callback(buffer, readSize);
    !buffer ?: free(buffer);
}

@end
