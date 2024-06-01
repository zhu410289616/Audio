//
//  CCDAUAudioPlayer.m
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/12.
//

#import "CCDAUAudioPlayer.h"
#import "CCDAudioDefines.h"
#import "CCDAudioUtil.h"

@interface CCDAUAudioPlayer ()

@property (nonatomic, assign) AudioUnit audioUnit;

@end

@implementation CCDAUAudioPlayer

@synthesize delegate;
@synthesize audioInput;
@synthesize isRunning = _isRunning;
@synthesize volume = _volume;
@synthesize numberOfLoops = _numberOfLoops;

- (void)dealloc
{
    [self cleanupAudioUnit];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _numberOfLoops = 1;
        [self setupAudioUnit];
    }
    return self;
}

#pragma mark - audio unit

static OSStatus CCDAUPlayCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData)
{
    CCDAUAudioPlayer *player = (__bridge CCDAUAudioPlayer *)inRefCon;
    id<CCDAudioPlayerDataInput> audioInput = player.audioInput;
    NSInteger channels = audioInput.audioFormat.mChannelsPerFrame;
    
    for (NSInteger i=0; i<channels; i++) {
        memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
    }
    
    __block AudioBufferList *inData;
    __block NSInteger bufferSize = 0;
    [audioInput input:^(AudioBufferList * _Nullable inAudioBufferList, NSInteger inSize) {
        inData = inAudioBufferList;
        bufferSize = inSize;
    } bufferSize:ioData->mBuffers[0].mDataByteSize];
    
    if (bufferSize <= 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            player.numberOfLoops--;
            if (player.numberOfLoops > 0) {
                [player replay];
            } else {
                [player stop];
            }
        });
        return noErr;
    }
    
    // 复制数据到各个声道
    for (NSInteger i=0; i<inData->mNumberBuffers; i++) {
        AudioBuffer *buffer = &inData->mBuffers[i];
        memcpy(ioData->mBuffers[i].mData, buffer->mData, buffer->mDataByteSize);
        ioData->mBuffers[i].mDataByteSize = buffer->mDataByteSize;
    }
    return noErr;
}

- (void)setupAudioUnit
{
    // init audio unit
    AudioComponentDescription audioDesc;
    audioDesc.componentType = kAudioUnitType_Output;
    audioDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    audioDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    audioDesc.componentFlags = 0;
    audioDesc.componentFlagsMask = 0;
    AudioComponent component = AudioComponentFindNext(NULL, &audioDesc);
    AudioComponentInstanceNew(component, &_audioUnit);
    
    AURenderCallbackStruct playCallback;
    playCallback.inputProc = CCDAUPlayCallback;
    playCallback.inputProcRefCon = (__bridge void *)self;
    
    OSStatus status = AudioUnitSetProperty(_audioUnit,
                         kAudioUnitProperty_SetRenderCallback,
                         kAudioUnitScope_Input,
                         0,/**OUTPUT_BUS*/
                         &playCallback,
                         sizeof(playCallback));
    if (status != noErr) {
        CCDAudioLogE(@"kAudioUnitProperty_SetRenderCallback: %@", @(status));
        return;
    }
    
    status = AudioUnitInitialize(_audioUnit);
    if (status != noErr) {
        CCDAudioLogE(@"AudioUnitInitialize: %@", @(status));
    }
}

- (void)cleanupAudioUnit
{
    if (_audioUnit) {
        AudioUnitUninitialize(_audioUnit);
        AudioComponentInstanceDispose(_audioUnit);
        _audioUnit = NULL;
    }
}

- (void)replay
{
    [self.audioInput end];
    [self.audioInput begin];
    OSStatus status = noErr;
    status = AudioOutputUnitStop(_audioUnit);
//    status = AudioUnitUninitialize(_audioUnit);
//    status = AudioUnitInitialize(_audioUnit);
    status = AudioOutputUnitStart(_audioUnit);
    CCDAudioLogD(@"replay AudioOutputUnitStart: %@", @(status));
}

#pragma mark - CCDAudioPlayerProvider

- (BOOL)prepare
{
    if ([self.delegate respondsToSelector:@selector(playerWillStart:)]) {
        [self.delegate playerWillStart:self];
    }
    
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
    
    status = AudioUnitSetProperty(_audioUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Output,
                         1,/**INPUT_BUS*/
                         &audioFormat,
                         sizeof(audioFormat));
    if (status != noErr) {
        CCDAudioLogE(@"kAudioUnitProperty_StreamFormat: %@", @(status));
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
    if (status != noErr) {
        if ([self.delegate respondsToSelector:@selector(playerWithError:)]) {
            NSError *error = CCDAudioMakeError(status, @"AudioOutputUnitStart");
            [self.delegate playerWithError:error];
        }
        AudioOutputUnitStop(self.audioUnit);
        return;
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
        return;
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
