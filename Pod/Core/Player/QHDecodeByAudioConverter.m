//
//  QHDecodeByAudioConverter.m
//  QHAudioConverterMan
//
//  Created by Anakin chen on 2021/4/13.
//

#import "QHDecodeByAudioConverter.h"

@interface QHDecodeByAudioConverter ()

@property (nonatomic, unsafe_unretained) AudioConverterRef audioConverter;

@property (nonatomic) AudioStreamPacketDescription *currentAudioStreamPacketDescription;
@property (nonatomic) AudioBufferList *currentBufferList;
//@property (nonatomic) AudioStreamBasicDescription in_ASBDes;
//@property (nonatomic) AudioStreamBasicDescription out_ASBDes;

@property (nonatomic) AudioBufferList *resBufferList;

@end

@implementation QHDecodeByAudioConverter

@synthesize inASBD = _inASBD;
@synthesize outASBD = _outASBD;

- (void)setup
{
    [self p_setup];
}

- (void)cleanup
{
    [self close];
}

- (AudioBufferList *)decodeRawData:(NSData *)rawData
{
    return [self decodeAudioSamepleBuffer:rawData];
}

- (AudioBufferList *)decodeAudioSamepleBuffer:(NSData *)data {
    @autoreleasepool {
        NSError *error = nil;
        OSStatus status;
        
        UInt32 outputMaxBufferSize = (UInt32)1024 * self.outASBD.mBytesPerFrame;
        UInt32 ioOutputDataPacketSize = (UInt32)1024;
    
        int in_mNumberBuffers = 1;
        self.currentBufferList->mNumberBuffers = in_mNumberBuffers;
        for (int i = 0; i < in_mNumberBuffers; ++i) {
            self.currentBufferList->mBuffers[i].mData = malloc(ioOutputDataPacketSize);
            memcpy(self.currentBufferList->mBuffers[i].mData, data.bytes, data.length);
            self.currentBufferList->mBuffers[i].mNumberChannels = 1;
            self.currentBufferList->mBuffers[i].mDataByteSize = (UInt32)data.length;
        }
        
        int out_mNumberBuffers = 2;
        size_t s = sizeof(AudioBufferList) + (self.outASBD.mChannelsPerFrame - 1) * sizeof(AudioBuffer);
        AudioBufferList *outAudioBufferList = (AudioBufferList *)malloc(s);
        outAudioBufferList->mNumberBuffers = out_mNumberBuffers;
        for (int i = 0; i < out_mNumberBuffers; i++) {
            outAudioBufferList->mBuffers[i].mNumberChannels = (uint32_t)1;
            outAudioBufferList->mBuffers[i].mDataByteSize = outputMaxBufferSize;
            outAudioBufferList->mBuffers[i].mData = malloc(outputMaxBufferSize);
        }
        
        status = AudioConverterFillComplexBuffer(self->_audioConverter, inputDataProc, (__bridge void * _Nullable)(self), &ioOutputDataPacketSize, outAudioBufferList, NULL);
//            NSLog(@"chen6>>status>>%d", (int)status);
        if (status == noErr) {
            int s = sizeof(AudioBufferList) + (outAudioBufferList->mNumberBuffers - 1) * sizeof(AudioBuffer);
            memcpy(self.resBufferList, outAudioBufferList, s);
        }
        else {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        }
        if (error) {
            NSLog(@"chen6>>error>>编码失败: %@",error);
        }
    }
    
    return self.resBufferList;
}

- (void)close {
    AudioConverterDispose(self.audioConverter);
}

#pragma mark - Private

- (void)p_setup {
//    AudioChannelLayoutTag channelLayoutTag = kAudioChannelLayoutTag_Mono;
//    AVAudioChannelLayout *layout = [[AVAudioChannelLayout alloc] initWithLayoutTag:channelLayoutTag];
//    AVAudioFormat *format = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:44100 interleaved:NO channelLayout:layout];
    
    NSUInteger bufferListSize = sizeof(AudioBufferList) + (6 - 1) * sizeof(AudioBuffer);
    _currentBufferList = malloc(bufferListSize);
    bufferListSize = sizeof(AudioBufferList) + (2 - 1) * sizeof(AudioBuffer);
    _resBufferList = malloc(bufferListSize);
    
    self.currentAudioStreamPacketDescription = malloc(sizeof(AudioStreamPacketDescription));
//    self.in_ASBDes = [[QHConfig sharestance] createAACAduioDes];
//    self.out_ASBDes = [[QHConfig sharestance] createPCMAduioDes];
    
    [self p_setupEncoder];
}

- (void)p_setupEncoder {
    AudioStreamBasicDescription inputAduioDes = self.inASBD;
    AudioStreamBasicDescription outputAudioDes = self.outASBD;
    
    // create an audio converter
    AudioConverterRef audioConverter;
    OSStatus acCreationResult = AudioConverterNew(&inputAduioDes, &outputAudioDes, &audioConverter);
    printf("创建 audio converter %p (status: %d)\n", audioConverter, acCreationResult);
    _audioConverter = audioConverter;
    
//    AudioClassDescription hardwareClassDesc = [self p_converterClassDescriptionWithManufacturer:kAppleHardwareAudioCodecManufacturer];
//    AudioClassDescription softwareClassDesc = [self p_converterClassDescriptionWithManufacturer:kAppleSoftwareAudioCodecManufacturer];
//
//    AudioClassDescription classDescs[] = {hardwareClassDesc, softwareClassDesc};
//    OSStatus ret = AudioConverterNewSpecific(&inputAduioDes, &outputAudioDes, sizeof(classDescs), classDescs, &_audioConverter);
//    if (ret != noErr) {
//        return;
//    }
}

- (AudioClassDescription)p_converterClassDescriptionWithManufacturer:(OSType)manufacturer {
    AudioClassDescription desc;
    // Decoder
    desc.mType = kAudioDecoderComponentType;
    desc.mSubType = kAudioFormatMPEG4AAC;
    desc.mManufacturer = manufacturer;
    return desc;
}

#pragma mark - Action

static OSStatus inputDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData) {
    QHDecodeByAudioConverter *thisSelf = (__bridge QHDecodeByAudioConverter *)(inUserData);
    
    int s = sizeof(AudioBufferList) + (1 - 1) * sizeof(AudioBuffer);
    memcpy(ioData, thisSelf.currentBufferList, s);
    UInt32 l = thisSelf.currentBufferList->mBuffers[0].mDataByteSize;
    
    // !!! if decode aac, must set outDataPacketDescription
    if (outDataPacketDescription != NULL) {
        *outDataPacketDescription = (thisSelf.currentAudioStreamPacketDescription);
        (*outDataPacketDescription)[0].mStartOffset             = 0;
        (*outDataPacketDescription)[0].mDataByteSize            = l;
        (*outDataPacketDescription)[0].mVariableFramesInPacket  = 0;
    }
    *ioNumberDataPackets = 1;
    
    return noErr;
}

@end
