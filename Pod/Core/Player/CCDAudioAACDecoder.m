//
//  CCDAudioAACDecoder.m
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/26.
//

#import "CCDAudioAACDecoder.h"
#import "CCDAudioDefines.h"
#import "CCDAudioUtil.h"

@interface CCDAudioAACDecoder ()

@property (nonatomic, assign) AudioConverterRef audioConverter;
@property (nonatomic) AudioStreamPacketDescription *currentASPD;

@property (nonatomic) AudioBufferList *inBufferList;
@property (nonatomic) AudioBufferList *outBufferList;

@end

@implementation CCDAudioAACDecoder

@synthesize inASBD = _inASBD;
@synthesize outASBD = _outASBD;

- (void)setup
{
    self.currentASPD = malloc(sizeof(AudioStreamPacketDescription));
    
    NSInteger inBufferListSize = sizeof(AudioBufferList) + (6 - 1) * sizeof(AudioBuffer);
    self.inBufferList = malloc(inBufferListSize);
    memset(self.inBufferList, 0, inBufferListSize);
    
    NSInteger outBufferListSize = sizeof(AudioBufferList) + (2 - 1) * sizeof(AudioBuffer);
    self.outBufferList = malloc(outBufferListSize);
    memset(self.outBufferList, 0, outBufferListSize);
    
    [self setupAudioConverter];
//    [self setupAudioConverterV2];
}

- (void)setupAudioConverter
{
    AudioStreamBasicDescription inputASBD = self.inASBD;
    AudioStreamBasicDescription outputASBD = self.outASBD;
    
    // create an audio converter
    AudioConverterRef audioConverter;
    OSStatus status = AudioConverterNew(&inputASBD, &outputASBD, &audioConverter);
    if (status != noErr) {
        CCDAudioLogE(@"AudioConverterNew: %@", @(status));
        return;
    }
    _audioConverter = audioConverter;
}

- (void)setupAudioConverterV2
{
    AudioStreamBasicDescription inputASBD = self.inASBD;
    AudioStreamBasicDescription outputASBD = self.outASBD;
    
    // create an audio converter
    AudioConverterRef audioConverter;
    AudioClassDescription hardwareClassDesc = [self classDescriptionWith:kAppleHardwareAudioCodecManufacturer];
    AudioClassDescription softwareClassDesc = [self classDescriptionWith:kAppleSoftwareAudioCodecManufacturer];

    AudioClassDescription classDescs[] = {
        hardwareClassDesc,
        softwareClassDesc
    };
    /// 使用AudioConverterNewSpecific创建时，输入流格式和输出流格式的声道数不同会出现-50错误；
    OSStatus status = AudioConverterNewSpecific(&inputASBD, &outputASBD, sizeof(classDescs), classDescs, &audioConverter);
    if (status != noErr) {
        CCDAudioLogE(@"AudioConverterNewSpecific: %@", @(status));
        return;
    }
    _audioConverter = audioConverter;
}

- (AudioClassDescription)classDescriptionWith:(OSType)manufacturer
{
    AudioClassDescription desc;
    // Decoder
    desc.mType = kAudioDecoderComponentType;
    desc.mSubType = kAudioFormatMPEG4AAC;
    desc.mManufacturer = manufacturer;
    return desc;
}

- (void)cleanup
{
    // free
    CCDAudioReleaseAudioBuffer(self.inBufferList);
//    CCDAudioReleaseAudioBuffer(self.outBufferList);
    
    if (_audioConverter) {
        AudioConverterDispose(_audioConverter);
        _audioConverter = NULL;
    }
}

- (AudioBufferList *)decodeRawData:(NSData *)rawData
{
    @autoreleasepool {
        void *bytes = (void *)rawData.bytes;
        NSInteger size = rawData.length;
//        [self decodeRawBytes:bytes size:size];
        [self decodeRaw:bytes size:size];
        return self.outBufferList;
    }
}

- (AudioBufferList *)decodeRaw:(void *)bytes size:(NSInteger)size
{
    //设置输入
    UInt32 inChannels = self.inASBD.mChannelsPerFrame;
    NSInteger inBufferListSize = sizeof(AudioBufferList) + (inChannels - 1) * sizeof(AudioBuffer);
    AudioBufferList *inAudioBufferList = malloc(inBufferListSize);
    memset(inAudioBufferList, 0, inBufferListSize);
    inAudioBufferList->mNumberBuffers = inChannels;
    for (UInt32 i=0; i<inChannels; i++) {
        inAudioBufferList->mBuffers[i].mNumberChannels = 1;
        inAudioBufferList->mBuffers[i].mData = malloc(size);
        memset(inAudioBufferList->mBuffers[i].mData, 0, size);
        inAudioBufferList->mBuffers[i].mDataByteSize = (UInt32)size;
        memcpy(inAudioBufferList->mBuffers[i].mData, bytes, size);
    }
    
    UInt32 bufferSize = 1024 * self.outASBD.mBytesPerFrame;
    //设置输出
    UInt32 outChannels = self.outASBD.mChannelsPerFrame;
    NSInteger outBufferListSize = sizeof(AudioBufferList) + (outChannels - 1) * sizeof(AudioBuffer);
    AudioBufferList *outAudioBufferList = (AudioBufferList *)malloc(outBufferListSize);
    memset(outAudioBufferList, 0, outBufferListSize);
    outAudioBufferList->mNumberBuffers = outChannels;
    for (UInt32 i=0; i<outChannels; i++) {
        uint8_t *buffer = (uint8_t *)malloc(bufferSize);
        memset(buffer, 0, bufferSize);
        
        outAudioBufferList->mBuffers[i].mNumberChannels = 1;
        outAudioBufferList->mBuffers[i].mDataByteSize = bufferSize;
        outAudioBufferList->mBuffers[i].mData = buffer;
    }
    
    UInt32 ioOutputDataPacketSize = 1024;

    /// 转码
    /// status为-50：初始化audioConverter的channels数量和实际输入的数据的channels不匹配；
    /// status为561015652：在inInputDataProc方法中需要填充outDataPacketDescription数据；
    OSStatus status = AudioConverterFillComplexBuffer(_audioConverter, inInputDataProc, inAudioBufferList, &ioOutputDataPacketSize, outAudioBufferList, NULL);
    if (status != noErr) {
        CCDAudioLogE(@"AudioConverterFillComplexBuffer: %@", @(status));
        CCDAudioResetAudioBuffer(self.outBufferList);
        return NULL;
    }
    
    int s = sizeof(AudioBufferList) + (outAudioBufferList->mNumberBuffers - 1) * sizeof(AudioBuffer);
    memcpy(self.outBufferList, outAudioBufferList, s);
    return self.outBufferList;
}

/// 将输入数据拷贝到 ioData 中；ioData 就是解码器解码时用到的真正输入缓冲区；
OSStatus inInputDataProc(AudioConverterRef inAudioConverter,
            UInt32 *ioNumberDataPackets,
            AudioBufferList *ioData,
            AudioStreamPacketDescription **outDataPacketDescription,
            void *inUserData)
{
    AudioBufferList audioBufferList = *(AudioBufferList *)inUserData;
    
//    UInt32 outChannels = audioBufferList.mNumberBuffers;
//    ioData->mNumberBuffers = outChannels;
//    for (UInt32 i=0; i<outChannels; i++) {
//        ioData->mBuffers[i].mNumberChannels = 1;
//        ioData->mBuffers[i].mData = audioBufferList.mBuffers[i].mData;
//        ioData->mBuffers[i].mDataByteSize = audioBufferList.mBuffers[i].mDataByteSize;
//    }
    
    UInt32 size = audioBufferList.mBuffers[0].mDataByteSize;
    ioData->mNumberBuffers = 1;
    ioData->mBuffers[0].mNumberChannels = 1;
    ioData->mBuffers[0].mData = audioBufferList.mBuffers[0].mData;
    ioData->mBuffers[0].mDataByteSize = size;
    
    // !!! if decode aac, must set outDataPacketDescription
    if (outDataPacketDescription != NULL) {
        *outDataPacketDescription = malloc(sizeof(AudioStreamPacketDescription));
        (*outDataPacketDescription)[0].mStartOffset             = 0;
        (*outDataPacketDescription)[0].mDataByteSize            = size;
        (*outDataPacketDescription)[0].mVariableFramesInPacket  = 0;
    }
    *ioNumberDataPackets = 1;
    
    return  noErr;
}

#pragma mark -

- (AudioBufferList *)decodeRawBytes:(void *)bytes size:(NSInteger)size
{
    UInt32 inChannels = 1;//self.inASBD.mChannelsPerFrame;
    self.inBufferList->mNumberBuffers = inChannels;
    for (UInt32 i=0; i<inChannels; i++) {
        self.inBufferList->mBuffers[i].mNumberChannels = 1;
        self.inBufferList->mBuffers[i].mData = malloc(size);
        memset(self.inBufferList->mBuffers[i].mData, 0, size);
        self.inBufferList->mBuffers[i].mDataByteSize = (UInt32)size;
        memcpy(self.inBufferList->mBuffers[i].mData, bytes, size);
    }
    
    UInt32 outMaxBufferSize = 1024 * self.outASBD.mBytesPerFrame;
    UInt32 outChannels = 2;//self.outASBD.mChannelsPerFrame;
    NSInteger outBufferListSize = sizeof(AudioBufferList) + (outChannels - 1) * sizeof(AudioBuffer);
    AudioBufferList *outAudioBufferList = (AudioBufferList *)malloc(outBufferListSize);
    memset(outAudioBufferList, 0, outBufferListSize);
    outAudioBufferList->mNumberBuffers = outChannels;
    for (UInt32 i=0; i<outChannels; i++) {
        outAudioBufferList->mBuffers[i].mNumberChannels = 1;
        outAudioBufferList->mBuffers[i].mDataByteSize = outMaxBufferSize;
        outAudioBufferList->mBuffers[i].mData = malloc(outMaxBufferSize);
        memset(outAudioBufferList->mBuffers[i].mData, 0, outMaxBufferSize);
    }
    
    UInt32 ioOutputDataPacketSize = 1024;
    
    OSStatus status = AudioConverterFillComplexBuffer(_audioConverter, inputDataProc, (__bridge void *)(self), &ioOutputDataPacketSize, outAudioBufferList, NULL);
    if (status != noErr) {
        CCDAudioLogE(@"AudioConverterFillComplexBuffer: %@", @(status));
        CCDAudioResetAudioBuffer(self.outBufferList);
        return NULL;
    }
    
    int s = sizeof(AudioBufferList) + (outAudioBufferList->mNumberBuffers - 1) * sizeof(AudioBuffer);
    memcpy(self.outBufferList, outAudioBufferList, s);
    
    // free
//    for (UInt32 i=0; i<outChannels; i++) {
//        outAudioBufferList->mBuffers[i].mDataByteSize = 0;
//        if (outAudioBufferList->mBuffers[i].mData) {
//            free(outAudioBufferList->mBuffers[i].mData);
//            outAudioBufferList->mBuffers[i].mData = NULL;
//        }
//    }
    
    return self.outBufferList;
}

static OSStatus inputDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData)
{
    CCDAudioAACDecoder *decoder = (__bridge CCDAudioAACDecoder *)(inUserData);
    
    NSInteger inChannels = 1;//decoder.inASBD.mChannelsPerFrame;
    NSUInteger s = sizeof(AudioBufferList) + (inChannels - 1) * sizeof(AudioBuffer);
    memcpy(ioData, decoder.inBufferList, s);
    UInt32 l = decoder.inBufferList->mBuffers[0].mDataByteSize;

    // !!! if decode aac, must set outDataPacketDescription
    if (outDataPacketDescription != NULL) {
        *outDataPacketDescription = (decoder.currentASPD);
        (*outDataPacketDescription)[0].mStartOffset             = 0;
        (*outDataPacketDescription)[0].mDataByteSize            = l;
        (*outDataPacketDescription)[0].mVariableFramesInPacket  = 0;
    }
    *ioNumberDataPackets = 1;
    
    return noErr;
}

@end
