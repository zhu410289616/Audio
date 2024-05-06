//
//  CCDAVAudioRecorder.m
//  Cicada
//
//  Created by ruhong zhu on 2020/6/13.
//

#import "CCDAVAudioRecorder.h"
#import <AVFoundation/AVFoundation.h>

@interface CCDAVAudioRecorder () <AVAudioRecorderDelegate>

@property (nonatomic, strong) AVAudioRecorder *recorder;

@end

@implementation CCDAVAudioRecorder

@synthesize delegate;
@synthesize audioOutput;
@synthesize isRunning;
@dynamic meteringEnabled;

#pragma mark - CCDAudioRecorderProvider

- (BOOL)isRunning
{
    return [self.recorder isRecording];
}

- (BOOL)prepareToRecord
{
    if ([self.delegate respondsToSelector:@selector(recorderWillStart:)]) {
        [self.delegate recorderWillStart:self];
    }
    
    NSString *filePath = self.audioOutput.filePath;
    CCDAudioLog(@"filePath: %@", filePath);
    if (filePath.length == 0) {
        return NO;
    }
    
    if ([self.audioOutput respondsToSelector:@selector(openAudioFile)]) {
        [self.audioOutput openAudioFile];
    }
    NSURL *audioFileURL = [NSURL fileURLWithPath:filePath];
    
    AudioStreamBasicDescription asbd = self.audioOutput.audioFormat;
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings setValue:@(asbd.mFormatID) forKey:AVFormatIDKey];
    [settings setValue:@(asbd.mSampleRate) forKey:AVSampleRateKey];
    [settings setValue:@(asbd.mChannelsPerFrame) forKey:AVNumberOfChannelsKey];
    [settings setValue:@(asbd.mBitsPerChannel) forKey:AVLinearPCMBitDepthKey];
    [settings setValue:@(AVAudioQualityHigh) forKey:AVEncoderAudioQualityKey];
    
    NSError *error = nil;
    self.recorder = [[AVAudioRecorder alloc] initWithURL:audioFileURL settings:settings error:&error];
    self.recorder.meteringEnabled = YES;
    if ((error || nil == self.recorder)
        && [self.delegate respondsToSelector:@selector(recorderWithError:)]) {
        [self.delegate recorderWithError:error];
        return NO;
    }
    
    self.recorder.delegate = self;
    return [self.recorder prepareToRecord];
}

- (void)startRecord
{
    self.isRunning = [self.recorder record];
    
    if ([self.delegate respondsToSelector:@selector(recorderDidStart:)]) {
        [self.delegate recorderDidStart:self];
    }
}

- (void)stopRecord
{
    if (!self.isRunning || !self.recorder) {
        return;
    }
    
    self.isRunning = NO;
    self.recorder.delegate = nil;
    [self.recorder stop];
    self.recorder = nil;
    
    if ([self.audioOutput respondsToSelector:@selector(closeAudioFile)]) {
        [self.audioOutput closeAudioFile];
    }
    
    if ([self.delegate respondsToSelector:@selector(recorderDidStop:)]) {
        [self.delegate recorderDidStop:self];
    }
}

- (void)setMeteringEnabled:(BOOL)meteringEnabled
{
    self.recorder.meteringEnabled = meteringEnabled;
}

- (BOOL)meteringEnabled
{
    return self.recorder.meteringEnabled;
}

- (float)averagePowerWithChannel:(int)channel
{
    [self.recorder updateMeters];
    return [self.recorder averagePowerForChannel:channel];
}

#pragma mark - AVAudioRecorderDelegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    if ([self.delegate respondsToSelector:@selector(recorderDidStop:)]) {
        [self.delegate recorderDidStop:self];
    }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error
{
    if ([self.delegate respondsToSelector:@selector(recorderWithError:)]) {
        [self.delegate recorderWithError:error];
    }
}

@end
