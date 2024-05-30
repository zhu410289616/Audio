//
//  CCDAudioRawDecoder.m
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/28.
//

#import "CCDAudioRawDecoder.h"
#import "CCDAudioDefines.h"
#import "CCDAudioUtil.h"

@interface CCDAudioRawDecoder ()

@property (nonatomic, assign) AudioConverterRef audioConverter;

@property (nonatomic) AudioStreamPacketDescription *currentASPD;
@property (nonatomic) AudioBufferList *inBufferList;
@property (nonatomic) AudioBufferList *outBufferList;

@end

@implementation CCDAudioRawDecoder

@synthesize inASBD = _inASBD;
@synthesize outASBD = _outASBD;

- (void)setup
{
    self.currentASPD = malloc(sizeof(AudioStreamPacketDescription));
    
//    [self setupAudioConverter];
    [self setupAudioConverterV2];
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
    if (_currentASPD) {
        free(_currentASPD);
        _currentASPD = NULL;
    }
    if (_audioConverter) {
        AudioConverterDispose(_audioConverter);
        _audioConverter = NULL;
    }
}

- (void)decodeRawData:(NSData *)rawData completion:(void (^)(AudioBufferList *outAudioBufferList))completion
{
    @autoreleasepool {
        UInt32 outChannels = self.outASBD.mChannelsPerFrame;
        UInt32 outSize = 1024 * self.outASBD.mBytesPerFrame;
        AudioBufferList *outAudioBufferList = CCDAudioBufferAlloc(outChannels, outSize);
        [self decodeWith:rawData outAudioBufferList:outAudioBufferList];
        !completion ?: completion(outAudioBufferList);
        CCDAudioBufferRelease(outAudioBufferList);
    }
}

- (AudioBufferList *)decodeRawData:(NSData *)rawData
{
    @autoreleasepool {
        void *bytes = (void *)rawData.bytes;
        NSInteger size = rawData.length;
        return [self decodeRawBytes:bytes size:size];
    }
}

- (AudioBufferList *)decodeRawBytes:(void *)bytes size:(NSInteger)size
{
    //设置输入
    UInt32 inChannels = self.inASBD.mChannelsPerFrame;
    AudioBufferList *inAudioBufferList = CCDAudioBufferAlloc(inChannels, bytes, size);
    self.inBufferList = inAudioBufferList;
    
    //设置输出
    UInt32 outChannels = self.outASBD.mChannelsPerFrame;
    UInt32 outSize = 1024 * self.outASBD.mBytesPerFrame;
    AudioBufferList *outAudioBufferList = CCDAudioBufferAlloc(outChannels, outSize);
    
    UInt32 ioOutputDataPacketSize = 1024;

    /// 转码
    /// status为-50：初始化audioConverter的channels数量和实际输入的数据的channels不匹配；
    /// status为561015652：在inInputDataProc方法中需要填充outDataPacketDescription数据；
    OSStatus status = AudioConverterFillComplexBuffer(_audioConverter, CCDAudioDecodeDataProc, (__bridge void *)(self), &ioOutputDataPacketSize, outAudioBufferList, NULL);
    if (status != noErr) {
        CCDAudioLogE(@"AudioConverterFillComplexBuffer: %@", @(status));
        CCDAudioBufferRelease(inAudioBufferList);
        CCDAudioBufferRelease(outAudioBufferList);
        return NULL;
    }
    
    CCDAudioBufferRelease(inAudioBufferList);
    return outAudioBufferList;
}

- (void)decodeWith:(NSData *)inData outAudioBufferList:(AudioBufferList *)outAudioBufferList
{
    if (inData.length == 0) { return; }
    
    UInt32 inChannels = self.inASBD.mChannelsPerFrame;
    void *bytes = (void *)inData.bytes;
    NSInteger size = inData.length;
    AudioBufferList *inAudioBufferList = CCDAudioBufferAlloc(inChannels, bytes, size);
    self.inBufferList = inAudioBufferList;
    
    UInt32 ioOutputDataPacketSize = 1024;
    
    /// 转码
    /// status为-50：初始化audioConverter的channels数量和实际输入的数据的channels不匹配；
    /// status为561015652：在inInputDataProc方法中需要填充outDataPacketDescription数据；
    OSStatus status = AudioConverterFillComplexBuffer(_audioConverter, CCDAudioDecodeDataProc, (__bridge void *)(self), &ioOutputDataPacketSize, outAudioBufferList, NULL);
    if (status != noErr) {
        CCDAudioLogE(@"AudioConverterFillComplexBuffer: %@", @(status));
    }
    
    CCDAudioBufferRelease(inAudioBufferList);
}

/// 将输入数据拷贝到 ioData 中；ioData 就是解码器解码时用到的真正输入缓冲区；
OSStatus CCDAudioDecodeDataProc(AudioConverterRef inAudioConverter,
                                UInt32 *ioNumberDataPackets,
                                AudioBufferList *ioData,
                                AudioStreamPacketDescription **outDataPacketDescription,
                                void *inUserData)
{
//    AudioBufferList audioBufferList = *(AudioBufferList *)inUserData;
    CCDAudioRawDecoder *context = (__bridge CCDAudioRawDecoder *)(inUserData);
    AudioBufferList *audioBufferList = context.inBufferList;
    
//    UInt32 outChannels = audioBufferList.mNumberBuffers;
//    ioData->mNumberBuffers = outChannels;
//    for (UInt32 i=0; i<outChannels; i++) {
//        ioData->mBuffers[i].mNumberChannels = 1;
//        ioData->mBuffers[i].mData = audioBufferList.mBuffers[i].mData;
//        ioData->mBuffers[i].mDataByteSize = audioBufferList.mBuffers[i].mDataByteSize;
//    }
    
    UInt32 size = audioBufferList->mBuffers[0].mDataByteSize;
    ioData->mNumberBuffers = 1;
    ioData->mBuffers[0].mNumberChannels = 1;
    ioData->mBuffers[0].mData = audioBufferList->mBuffers[0].mData;
    ioData->mBuffers[0].mDataByteSize = size;
    
    // !!! if decode aac, must set outDataPacketDescription
    if (outDataPacketDescription != NULL) {
//        *outDataPacketDescription = malloc(sizeof(AudioStreamPacketDescription));
        *outDataPacketDescription = context.currentASPD;
        (*outDataPacketDescription)[0].mStartOffset             = 0;
        (*outDataPacketDescription)[0].mDataByteSize            = size;
        (*outDataPacketDescription)[0].mVariableFramesInPacket  = 0;
    }
    *ioNumberDataPackets = 1;
    
    return  noErr;
}

@end
