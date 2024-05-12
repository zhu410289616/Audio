//
//  CCDAUAudioRecorder.m
//  Pods
//
//  Created by 十年之前 on 2023/7/31.
//

#import "CCDAUAudioRecorder.h"
#import "CCDAudioDefines.h"

@interface CCDAUAudioRecorder ()

@property (nonatomic, assign) AudioUnit audioUnit;
@property (nonatomic, assign) CGFloat db;

@end

@implementation CCDAUAudioRecorder

@synthesize delegate;
@synthesize audioOutput;
@synthesize isRunning;
@synthesize meteringEnabled = _meteringEnabled;

#pragma mark - record input proc

static OSStatus CCDAURecordCallback(void *                       inRefCon,
                                    AudioUnitRenderActionFlags * ioActionFlags,
                                    const AudioTimeStamp *       inTimeStamp,
                                    UInt32                       inBusNumber,
                                    UInt32                       inNumberFrames,
                                    AudioBufferList * __nullable ioData)
{
    CCDAUAudioRecorder *recorder = (__bridge CCDAUAudioRecorder *)(inRefCon);
    NSInteger channels = recorder.audioOutput.audioFormat.mChannelsPerFrame;
    static UInt32 constBufferSize = 5000;
    
    AudioBufferList bufferList = {0};
    bufferList.mNumberBuffers = (UInt32)channels;
    for (NSInteger i=0; i<channels; i++) {
        bufferList.mBuffers[0].mDataByteSize = constBufferSize;
        bufferList.mBuffers[0].mData = malloc(constBufferSize);
    }
    
    OSStatus status = noErr;
    status = AudioUnitRender(recorder.audioUnit,
                             ioActionFlags,
                             inTimeStamp,
                             inBusNumber,
                             inNumberFrames,
                             &bufferList);
    if (status != noErr) {
        CCDAudioLogE(@"AudioUnitRender: %@", @(status));
        return status;
    }
    
    //录音完成，可以对音频数据进行处理了，保存下来或者计算录音的分贝数等等
    //如果你需要计算录音时的音量，显示录音动画，这里就可以通过bufferList->mBuffers[0].mData计算得出
    Byte *bufferData = bufferList.mBuffers[0].mData;
    UInt32 bufferSize = bufferList.mBuffers[0].mDataByteSize;
    //因为我们的采样位数是16个字节，也就是需要用SInt16来存储
    SInt16 *shortBuffer = (SInt16 *)bufferData;
    NSInteger pcmAllLen = 0;
    //因为原数据bufferData是8位存储的，但是我们采样是16位，所以这里长度要减半
    for(int i=0;i<bufferSize/2;++i) {
        NSInteger tmp = shortBuffer[i];
        pcmAllLen += tmp*tmp;
    }
//    CGFloat db = 10 * log10((CGFloat)pcmAllLen / bufferSize);
    //这里db就是我们计算出来的，当前这段音频的通过声压计算分贝算出来的，最大是90.3分贝
    recorder.db = log10((CGFloat)pcmAllLen / bufferSize);
    
    [recorder.audioOutput write:&bufferList];
    
    for (NSInteger i=0; i<channels; i++) {
        if (bufferList.mBuffers[0].mData) {
            free(bufferList.mBuffers[0].mData);
            bufferList.mBuffers[0].mData = NULL;
        }
    }
    return status;
}

#pragma mark - CCDAudioRecorderProvider

- (BOOL)prepare
{
    if ([self.delegate respondsToSelector:@selector(recorderWillStart:)]) {
        [self.delegate recorderWillStart:self];
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
    AudioStreamBasicDescription audioFormat = self.audioOutput.audioFormat;
    OSStatus status = noErr;
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
    
    //打开录音流功能，否则无法录音
    //但是播放能力是默认打开的，所以不需要设置OUTPUT_BUS的kAudioUnitScope_Output
    UInt32 enableRecord = 1;
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  1,/**INPUT_BUS*/
                                  &enableRecord,
                                  sizeof(enableRecord));
    if (status != noErr) {
        CCDAudioLogE(@"kAudioOutputUnitProperty_EnableIO: %@", @(status));
        return NO;
    }
    
    AURenderCallbackStruct recordCallback;
    recordCallback.inputProc = CCDAURecordCallback;
    recordCallback.inputProcRefCon = (__bridge void *)self;
    
    status = AudioUnitSetProperty(_audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Output,
                                  1,/**INPUT_BUS*/
                                  &recordCallback,
                                  sizeof(recordCallback));
    if (status != noErr) {
        CCDAudioLogE(@"kAudioOutputUnitProperty_SetInputCallback: %@", @(status));
        return NO;
    }
    
    status = AudioUnitInitialize(_audioUnit);
    if (status != noErr) {
        CCDAudioLogE(@"AudioUnitInitialize: %@", @(status));
        return NO;
    }
    self.meteringEnabled = YES;
    return YES;
}

- (void)start
{
    if (self.isRunning) {
        return;
    }
    self.isRunning = YES;
    
    [self.audioOutput begin];
    OSStatus status = AudioOutputUnitStart(_audioUnit);
    CCDAudioLogD(@"AudioOutputUnitStart: %@", @(status));
    if (status != noErr && [self.delegate respondsToSelector:@selector(recorderWithError:)]) {
        NSError *error = CCDAudioMakeError(status, @"AudioOutputUnitStart");
        [self.delegate recorderWithError:error];
    }
    
    if ([self.delegate respondsToSelector:@selector(recorderDidStart:)]) {
        [self.delegate recorderDidStart:self];
    }
}

- (void)stop
{
    if (!self.isRunning) {
        return;
    }
    self.isRunning = NO;
    
    [self.audioOutput end];
    OSStatus status = AudioOutputUnitStop(_audioUnit);
    CCDAudioLogD(@"AudioOutputUnitStop: %@", @(status));
    
    if ([self.delegate respondsToSelector:@selector(recorderDidStop:)]) {
        [self.delegate recorderDidStop:self];
    }
}

- (float)averagePowerWithChannel:(int)channel
{
    return self.db;
}

@end
