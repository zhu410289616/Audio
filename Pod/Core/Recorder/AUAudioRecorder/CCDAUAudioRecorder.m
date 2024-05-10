//
//  CCDAUAudioRecorder.m
//  Pods
//
//  Created by 十年之前 on 2023/7/31.
//

#import "CCDAUAudioRecorder.h"

@interface CCDAUAudioRecorder ()
{
    AudioUnit _audioUnit;
}

@end

@implementation CCDAUAudioRecorder

@synthesize delegate;
@synthesize audioOutput;
@synthesize isRunning;
@synthesize meteringEnabled = _meteringEnabled;

#pragma mark - record input proc

OSStatus CCDAudioUnitRecordCallback(void *                       inRefCon,
                                    AudioUnitRenderActionFlags * ioActionFlags,
                                    const AudioTimeStamp *       inTimeStamp,
                                    UInt32                       inBusNumber,
                                    UInt32                       inNumberFrames,
                                    AudioBufferList * __nullable ioData)
{
    CCDAUAudioRecorder *recorder = (__bridge CCDAUAudioRecorder *)(inRefCon);
    id<CCDAudioUnitRecorderOutput> audioOutput = nil;
    if ([recorder.audioOutput conformsToProtocol:@protocol(CCDAudioUnitRecorderOutput)]) {
        audioOutput = (id<CCDAudioUnitRecorderOutput>)recorder.audioOutput;
    }
    
    AudioBufferList bufferList = {0};
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mData = NULL;
    bufferList.mBuffers[0].mDataByteSize = 0;
    bufferList.mBuffers[0].mNumberChannels = audioOutput.audioFormat.mChannelsPerFrame;
    
    OSStatus status = AudioUnitRender(recorder->_audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufferList);
    if (status != noErr) {
        CCDAudioLogError(@"CCDAudioUnitInputCallback error: %@", @(status));
        return status;
    }
    
    UInt32 dataSize = bufferList.mBuffers[0].mDataByteSize;
    void *data = bufferList.mBuffers[0].mData;
    if (audioOutput && dataSize > 0 && data) {
        char *dst = (char *)calloc(1, dataSize);
        memcpy(dst, data, dataSize);
        [audioOutput receiveAudio:dst size:dataSize];
//        [audioOutput receiveAudio:bufferList];
    }
    
    return status;
}

#pragma mark - CCDAudioRecorderProvider

- (BOOL)prepareToRecord
{
    @try {
        if ([self.delegate respondsToSelector:@selector(recorderWillStart:)]) {
            [self.delegate recorderWillStart:self];
        }
        
        // init audio unit
        AudioComponentDescription inputCompDesc = {0};
        inputCompDesc.componentType = kAudioUnitType_Output;
        inputCompDesc.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
        inputCompDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
        inputCompDesc.componentFlags = 0;
        inputCompDesc.componentFlagsMask = 0;
        
        AudioComponent component = AudioComponentFindNext(NULL, &inputCompDesc);
        OSStatus ret = AudioComponentInstanceNew(component, &_audioUnit);
        if (ret != noErr) {
            return NO;
        }
        
        // specify the recording format
        AudioStreamBasicDescription outStreamDes = self.audioOutput.audioFormat;
        
        AudioUnitSetProperty(_audioUnit,
                             kAudioUnitProperty_StreamFormat,
                             kAudioUnitScope_Output,
                             1,/**INPUT_BUS*/
                             &outStreamDes,
                             sizeof(outStreamDes));
        
        //打开录音流功能，否则无法录音
        //但是播放能力是默认打开的，所以不需要设置OUTPUT_BUS的kAudioUnitScope_Output
        UInt32 enableRecord = 1;
        AudioUnitSetProperty(_audioUnit,
                             kAudioOutputUnitProperty_EnableIO,
                             kAudioUnitScope_Input,
                             1,/**INPUT_BUS*/
                             &enableRecord,
                             sizeof(enableRecord));
        
        //录音的回调方法，INPUT_BUS收音之后拿到的音频数据，会通过这个静态方法回调给我们
        AURenderCallbackStruct recordCallback;
        recordCallback.inputProc = CCDAudioUnitRecordCallback;
        recordCallback.inputProcRefCon = (__bridge void *)self;
        OSStatus status = noErr;
        status = AudioUnitSetProperty(_audioUnit,
                                      kAudioOutputUnitProperty_SetInputCallback,
                                      kAudioUnitScope_Output,
                                      1,/**INPUT_BUS*/
                                      &recordCallback,
                                      sizeof(recordCallback));
        
        //初始化，注意，这里只是初始化，还没开始播放
        //这里初始化出现错误，请检查audioPCMFormat，outputFormat等格式是否有设置错误的
        //比如设置了双声道，但是没有设置kAudioFormatFlagIsNonInterleaved
        status = AudioUnitInitialize(_audioUnit);
        if (status != noErr) {
            return NO;
        }
        
        if ([self.audioOutput respondsToSelector:@selector(openAudioFile)]) {
            [self.audioOutput openAudioFile];
        }
    } @catch (NSException *exception) {
        NSError *error = CCDAudioMakeError(-1, @"start audio unit error");
        if ([self.delegate respondsToSelector:@selector(recorderWithError:)]) {
            [self.delegate recorderWithError:error];
        }
    }
    return YES;
}

- (void)startRecord
{
    OSStatus status = AudioOutputUnitStart(_audioUnit);
    if (status != noErr) {
        NSError *error = CCDAudioMakeError(status, @"start audio unit error");
        if ([self.delegate respondsToSelector:@selector(recorderWithError:)]) {
            [self.delegate recorderWithError:error];
        }
        return;
    }
    
    self.isRunning = YES;
    
    if ([self.delegate respondsToSelector:@selector(recorderDidStart:)]) {
        [self.delegate recorderDidStart:self];
    }
}

- (void)stopRecord
{
    if (!self.isRunning) {
        return;
    }
    
    self.isRunning = NO;
    OSStatus status = AudioOutputUnitStop(_audioUnit);
    if (status != noErr) {
        NSError *error = CCDAudioMakeError(status, @"start audio unit error");
        if ([self.delegate respondsToSelector:@selector(recorderWithError:)]) {
            [self.delegate recorderWithError:error];
        }
    }
    
    if ([self.audioOutput respondsToSelector:@selector(closeAudioFile)]) {
        [self.audioOutput closeAudioFile];
    }
    // stop
    if ([self.delegate respondsToSelector:@selector(recorderDidStop:)]) {
        [self.delegate recorderDidStop:self];
    }
}

@end
