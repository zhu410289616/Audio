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
        [self decodeRawBytes:bytes size:size];
        return self.outBufferList;
    }
}

- (AudioBufferList *)decodeRawBytes:(void *)bytes size:(NSInteger)size
{
    UInt32 ioOutputDataPacketSize = 1024;
    
    UInt32 inChannels = 1;//self.inASBD.mChannelsPerFrame;
    self.inBufferList->mNumberBuffers = inChannels;
    for (UInt32 i=0; i<inChannels; i++) {
        self.inBufferList->mBuffers[i].mNumberChannels = 1;
        self.inBufferList->mBuffers[i].mData = malloc(ioOutputDataPacketSize);
        memset(self.inBufferList->mBuffers[i].mData, 0, ioOutputDataPacketSize);
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
    
    OSStatus status = AudioConverterFillComplexBuffer(_audioConverter, inputDataProc, (__bridge void *)(self), &ioOutputDataPacketSize, outAudioBufferList, NULL);
    if (status != noErr) {
        CCDAudioLogE(@"AudioConverterFillComplexBuffer: %@", @(status));
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
