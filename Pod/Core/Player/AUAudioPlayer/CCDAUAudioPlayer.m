//
//  CCDAUAudioPlayer.m
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/12.
//

#import "CCDAUAudioPlayer.h"
#import "CCDAudioDefines.h"

@interface CCDAUAudioPlayer ()

@property (nonatomic, assign) AudioUnit audioUnit;

@end

@implementation CCDAUAudioPlayer

@synthesize delegate;
@synthesize audioInput;
@synthesize isRunning;
@dynamic volume;

- (void)dealloc
{
    OSStatus status = AudioOutputUnitStop(_audioUnit);
    CCDAudioLogD(@"AudioOutputUnitStop: %@", @(status));
}

#pragma mark - CCDAudioPlayerProvider

- (BOOL)isRunning
{
    return NO;
}

- (void)setVolume:(float)volume
{
//    self.player.volume = volume;
}

- (float)volume
{
    return 0.0f;
}

- (void)setNumberOfLoops:(NSInteger)numberOfLoops
{
//    self.player.numberOfLoops = numberOfLoops;
}

- (NSInteger)numberOfLoops
{
    return 0;
}

static OSStatus CCDAUPlayCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData)
{
    CCDAUAudioPlayer *player = (__bridge CCDAUAudioPlayer *)inRefCon;
    
    __block void * buffer = NULL;
    __block NSInteger bufferSize = 0;
    [player.audioInput read:^(void * _Nullable bytes, NSInteger size) {
        buffer = bytes;
        bufferSize = size;
    } maxSize:ioData->mBuffers[0].mDataByteSize];
    
    NSInteger channels = player.audioInput.audioFormat.mChannelsPerFrame;
    if (bufferSize <= 0) {
        for (NSInteger i=0; i<channels; i++) {
            memset(ioData->mBuffers[i].mData, 0, bufferSize);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [player stop];
        });
        return noErr;
    }
    
    // 复制数据到各个声道
    for (NSInteger i=0; i<channels; i++) {
        memcpy(ioData->mBuffers[i].mData, buffer, bufferSize);
        ioData->mBuffers[i].mDataByteSize = (UInt32)bufferSize;
    }
    return noErr;
}

- (BOOL)prepare
{
    if ([self.delegate respondsToSelector:@selector(playerWillStart:)]) {
        [self.delegate playerWillStart:self];
    }
    
    // init audio unit
    AudioComponentDescription audioDesc;
    audioDesc.componentType = kAudioUnitType_Output;
    audioDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    audioDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    audioDesc.componentFlags = 0;
    audioDesc.componentFlagsMask = 0;
    AudioComponent component = AudioComponentFindNext(NULL, &audioDesc);
    AudioComponentInstanceNew(component, &_audioUnit);
    
    // specify the recording format
    AudioStreamBasicDescription audioFormat = [self.audioInput audioFormat];
    OSStatus status = noErr;
    status = AudioUnitSetProperty(_audioUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Input,
                         0,/**OUTPUT_BUS*/
                         &audioFormat,
                         sizeof(audioFormat));
    if (status != noErr) {
        CCDAudioLogE(@"kAudioUnitProperty_StreamFormat: %@", @(status));
        return NO;
    }
    
    AURenderCallbackStruct playCallback;
    playCallback.inputProc = CCDAUPlayCallback;
    playCallback.inputProcRefCon = (__bridge void *)self;
    
    status = AudioUnitSetProperty(_audioUnit,
                         kAudioUnitProperty_SetRenderCallback,
                         kAudioUnitScope_Input,
                         0,/**OUTPUT_BUS*/
                         &playCallback,
                         sizeof(playCallback));
    if (status != noErr) {
        CCDAudioLogE(@"kAudioUnitProperty_SetRenderCallback: %@", @(status));
        return NO;
    }
    
    status = AudioUnitInitialize(_audioUnit);
    if (status != noErr) {
        CCDAudioLogE(@"AudioUnitInitialize: %@", @(status));
        return NO;
    }
    return YES;
}

- (void)play
{
    if (self.isRunning) {
        return;
    }
    self.isRunning = YES;
    
    [self.audioInput begin];
    OSStatus status = AudioOutputUnitStart(self.audioUnit);
    CCDAudioLogD(@"AudioOutputUnitStart: %@", @(status));
    if (status != noErr && [self.delegate respondsToSelector:@selector(playerWithError:)]) {
        NSError *error = CCDAudioMakeError(status, @"AudioOutputUnitStart");
        [self.delegate playerWithError:error];
    }
    
    if ([self.delegate respondsToSelector:@selector(playerDidStart:)]) {
        [self.delegate playerDidStart:self];
    }
}

- (void)pause
{
    [self stop];
}

- (void)stop
{
    if (!self.isRunning) {
//        return;
    }
    self.isRunning = NO;
    
    [self.audioInput end];
    OSStatus status = AudioOutputUnitStop(self.audioUnit);
    CCDAudioLogD(@"AudioOutputUnitStop: %@", @(status));
    
    if ([self.delegate respondsToSelector:@selector(playerDidStop:)]) {
        [self.delegate playerDidStop:self];
    }
}

@end
