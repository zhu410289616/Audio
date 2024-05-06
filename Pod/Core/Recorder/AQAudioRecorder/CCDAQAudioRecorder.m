//
//  CCDAQAudioRecorder.m
//  Cicada
//
//  Created by ruhong zhu on 2020/6/13.
//

#import "CCDAQAudioRecorder.h"
#import "CCDAudioDefines.h"
#import "CCDAudioRecorderOutput.h"

//缓存区的个数，3个一般不用改
#define kCCDNumberAudioQueueBuffers 3

//每次的音频输入队列缓存区所保存的是多少秒的数据
#define kCCDBufferDurationSeconds 0.26

@interface CCDAQAudioRecorder ()
{
    AudioQueueRef _audioQueue;                                          //音频输入队列
    AudioQueueBufferRef _audioBuffers[kCCDNumberAudioQueueBuffers];        //音频输入缓冲区
}

@end

@implementation CCDAQAudioRecorder

@synthesize delegate;
@synthesize audioOutput;
@synthesize isRunning;
@synthesize meteringEnabled = _meteringEnabled;

#pragma mark - AudioQueue

/** AudioQueue callback function, called when an input buffers has been filled. */
void CCDAudioQueueInputBufferHandler(void *inUserData,
                                     AudioQueueRef inAQ,
                                     AudioQueueBufferRef inBuffer,
                                     const AudioTimeStamp *inStartTime,
                                     UInt32 inNumPackets,
                                     const AudioStreamPacketDescription *inPacketDesc)
{
    if (inNumPackets == 0) {
        return;
    }
//    CCDAudioLogError(@"inNumPackets: %d", inNumPackets);
    
    id<CCDAudioRecorderProvider> recorder = nil;
    @try {
        CCDAudioQueueInputData aqInputData;
        aqInputData.inUserData = inUserData;
        aqInputData.inAQ = inAQ;
        aqInputData.inBuffer = inBuffer;
        aqInputData.inStartTime = inStartTime;
        aqInputData.inNumPackets = inNumPackets;
        aqInputData.inPacketDesc = inPacketDesc;
        
        recorder = (__bridge id<CCDAudioRecorderProvider>)(inUserData);
        id<CCDAudioQueueRecorderOutput> audioOutput = nil;
        if ([recorder.audioOutput conformsToProtocol:@protocol(CCDAudioQueueRecorderOutput)]) {
            audioOutput = (id<CCDAudioQueueRecorderOutput>)recorder.audioOutput;
        } else {
            CCDAudioLogError(@"Get audio queue recorder output error");
        }
        if ([audioOutput respondsToSelector:@selector(receiveAudio:size:)]) {
            [audioOutput receiveAudio:inBuffer->mAudioData size:inBuffer->mAudioDataByteSize];
        } else if ([audioOutput respondsToSelector:@selector(didReceiveAudio:)]) {
            [audioOutput didReceiveAudio:aqInputData];
        }
        
        // if we're not stopping, re-enqueue the buffe so that it gets filled again
        if ([recorder isRunning]) {
            OSStatus status = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
            if (status != noErr) {
                CCDAudioLogError(@"Audio buffer re-enqueue the buffe error");
            }
        }
        
    } @catch (NSException *exception) {
        CCDAudioLogError(@"CCDAudioQueueInputBufferHandler: %@", exception);
    } @finally {
        
    }
}

#pragma mark - CCDAudioRecorderProvider

- (BOOL)prepareToRecord
{
    @try {
        if ([self.delegate respondsToSelector:@selector(recorderWillStart:)]) {
            [self.delegate recorderWillStart:self];
        }
        
        // specify the recording format
        AudioStreamBasicDescription inFormat = self.audioOutput.audioFormat;
        
        // create the queue
        OSStatus status = AudioQueueNewInput(&inFormat,
                                             CCDAudioQueueInputBufferHandler,
                                             (__bridge void * _Nullable)(self),
                                             NULL,
                                             NULL,
                                             0,
                                             &_audioQueue);
        if (status != noErr) {
            [self __trackErrorWithCode:status message:@"create the queue"];
            return NO;
        }
        
        // create the audio file
        id<CCDAudioQueueRecorderOutput> audioOutput = nil;
        if ([self.audioOutput conformsToProtocol:@protocol(CCDAudioQueueRecorderOutput)]) {
            audioOutput = (id<CCDAudioQueueRecorderOutput>)self.audioOutput;
        }
        if ([audioOutput respondsToSelector:@selector(openAudioFile)]) {
            [audioOutput openAudioFile];
        }
        
        // copy the cookie first to give the file object as much info as we can about the data going in
        // not necessary for pcm, but required for some compressed audio
        NSError *error = nil;
        [audioOutput copyEncoderCookieToFile:_audioQueue error:&error];
        if (error) {
            NSDictionary *userInfo = error.userInfo;
            [self __trackErrorWithCode:error.code message:userInfo[NSLocalizedDescriptionKey]];
            return NO;
        }
        
        // allocate and enqueue buffers
        UInt32 bufferByteSize = [self computeRecordBufferSize:&inFormat seconds:kCCDBufferDurationSeconds];
        if ([audioOutput respondsToSelector:@selector(computeRecordBufferSize:)]) {
            bufferByteSize = [audioOutput computeRecordBufferSize:&inFormat];
        }
        for (int i=0; i<kCCDNumberAudioQueueBuffers; ++i) {
            status = AudioQueueAllocateBuffer(_audioQueue, bufferByteSize, &_audioBuffers[i]);
            NSAssert(status == noErr, @"AudioQueueAllocateBuffer failed");
            status = AudioQueueEnqueueBuffer(_audioQueue, _audioBuffers[i], 0, NULL);
            NSAssert(status == noErr, @"AudioQueueEnqueueBuffer failed");
        }
        
        // level meter
        self.meteringEnabled = YES;
    } @catch (NSException *exception) {
        
    }
    return YES;
}

- (void)startRecord
{
    // start the queue
    OSStatus status = AudioQueueStart(_audioQueue, NULL);
    if (status != noErr) {
        [self __trackErrorWithCode:status message:@"start the queue"];
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
    OSStatus status = AudioQueueStop(_audioQueue, true);
    if (status != noErr) {
        [self __trackErrorWithCode:status message:@"stop the queue"];
    }
    
    // a codec may update its cookie at the end of an encoding session, so reapply it to the file now
    id<CCDAudioQueueRecorderOutput> audioOutput = nil;
    if ([self.audioOutput conformsToProtocol:@protocol(CCDAudioQueueRecorderOutput)]) {
        audioOutput = (id<CCDAudioQueueRecorderOutput>)self.audioOutput;
    }
    NSError *error = nil;
    [audioOutput copyEncoderCookieToFile:_audioQueue error:&error];
    if (error) {
        NSDictionary *userInfo = error.userInfo;
        [self __trackErrorWithCode:error.code message:userInfo[NSLocalizedDescriptionKey]];
    }
    if ([audioOutput respondsToSelector:@selector(closeAudioFile)]) {
        [audioOutput closeAudioFile];
    }
    
    // stop
    if ([self.delegate respondsToSelector:@selector(recorderDidStop:)]) {
        [self.delegate recorderDidStop:self];
    }
}

- (void)setMeteringEnabled:(BOOL)meteringEnabled
{
    UInt32 val = meteringEnabled ? 1 : 0;
    OSStatus status = AudioQueueSetProperty(_audioQueue, kAudioQueueProperty_EnableLevelMetering, &val, sizeof(UInt32));
    _meteringEnabled = (status == kAudioSessionNoError) ? YES : NO;
}

- (float)averagePowerWithChannel:(int)channel
{
    AudioQueueLevelMeterState meters[1];
    UInt32 len = sizeof(meters);
    OSStatus status = AudioQueueGetProperty(_audioQueue, kAudioQueueProperty_CurrentLevelMeterDB, meters, &len);
    if (status) {
        CCDAudioLog(@"AudioQueueGetProperty(CurrentLevelMeter) returned %@", @(status));
    }
    return meters[0].mAveragePower;
}

#pragma mark -

- (UInt32)computeRecordBufferSize:(const AudioStreamBasicDescription *)format seconds:(float)seconds
{
    UInt32 bytes = 0;
    
    @try {
        UInt32 frames = ceil(seconds * format->mSampleRate);
        
        if (format->mBytesPerFrame > 0) {
            bytes = frames * format->mBytesPerFrame;
        } else {
            UInt32 maxPacketSize;
            if (format->mBytesPerPacket > 0) {
                maxPacketSize = format->mBytesPerPacket;// constant packet size
            } else {
                UInt32 propertySize = sizeof(maxPacketSize);
                OSStatus status = AudioQueueGetProperty(_audioQueue, kAudioQueueProperty_MaximumOutputPacketSize, &maxPacketSize, &propertySize);
                NSAssert(status == noErr, @"couldn't get queue's maximum output packet size");
            }//if
            UInt32 packets = 0;
            if (format->mFramesPerPacket > 0) {
                packets = frames / format->mFramesPerPacket;
            } else {
                packets = frames;// worst-case scenario: 1 frame in a packet
            }//if
            if (packets == 0) {// sanity check
                packets = 1;
            }
            bytes = packets * maxPacketSize;
        }
    }
    @catch (NSException *exception) {
        CCDAudioLog(@"computeRecordBufferSize exception: %@", exception.description);
    }
    
    return bytes;
}

#pragma mark - error

- (void)__trackErrorWithCode:(NSInteger)code message:(NSString *)message
{
    NSError *error = CCDAudioMakeError(code, message);
    if ([self.delegate respondsToSelector:@selector(recorderWithError:)]) {
        [self.delegate recorderWithError:error];
    }
}

@end
