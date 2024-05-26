//
//  CCDAudioPlayerInputAAC.m
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/20.
//

#import "CCDAudioPlayerInputAAC.h"
#import "CCDAudioAACFileReader.h"
#import "CCDAudioUtil.h"

const static NSInteger OUTPUT_BUS = 0;
const static NSInteger CONST_BUFFER_SIZE = 5000;
const static NSInteger NO_MORE_DATA = -100000;

@interface CCDAudioPlayerInputAAC ()

@property (nonatomic, strong) NSURL *audioURL;
@property (nonatomic, strong) CCDAudioAACFileReader *aacReader;

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
        _aacReader = [[CCDAudioAACFileReader alloc] initWithFilePath:audioURL.path];
    }
    return self;
}

#pragma mark -

- (void)setupAudioFormat:(NSInteger)sampleRate
{
    NSInteger channels = 1;
    self.audioFormat = CCDAudioCreateASBD_PCM16(sampleRate, channels);
    self.srcAudioFormat = CCDAudioCreateASBD_AAC(sampleRate, channels);
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
