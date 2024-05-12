//
//  CCDAVAudioPlayer.m
//  Cicada
//
//  Created by ruhong zhu on 2020/6/14.
//

#import "CCDAVAudioPlayer.h"

@interface CCDAVAudioPlayer () <AVAudioPlayerDelegate>

@property (nonatomic, strong) AVAudioPlayer *player;

@end

@implementation CCDAVAudioPlayer

@synthesize delegate;
@synthesize audioInput;
@synthesize isRunning;
@dynamic volume;

#pragma mark - CCDAudioPlayerProvider

- (BOOL)isRunning
{
    return [self.player isPlaying];
}

- (void)setVolume:(float)volume
{
    self.player.volume = volume;
}

- (float)volume
{
    return self.player.volume;
}

- (void)setNumberOfLoops:(NSInteger)numberOfLoops
{
    self.player.numberOfLoops = numberOfLoops;
}

- (NSInteger)numberOfLoops
{
    return self.player.numberOfLoops;
}

- (BOOL)prepare
{
    if ([self.delegate respondsToSelector:@selector(playerWillStart:)]) {
        [self.delegate playerWillStart:self];
    }
    
    NSString *filePath = self.audioInput.audioPath;
    CCDAudioLog(@"filePath: %@", filePath);
    if (filePath.length == 0) {
        return NO;
    }
    NSURL *audioFileURL = [NSURL fileURLWithPath:filePath];
    
    NSError *error = nil;
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileURL error:&error];
    if ((error || nil == self.player)
        && [self.delegate respondsToSelector:@selector(playerWithError:)]) {
        [self.delegate playerWithError:error];
        return NO;
    }
    
    self.player.delegate = self;
    return [self.player prepareToPlay];
}

- (void)play
{
    self.isRunning = [self.player play];
    
    if ([self.delegate respondsToSelector:@selector(playerDidStart:)]) {
        [self.delegate playerDidStart:self];
    }
}

- (void)pause
{
    [self.player pause];
}

- (void)stop
{
    if (!self.isRunning || !self.player) {
        return;
    }
    
    self.isRunning = NO;
    [self.player stop];
    self.player.delegate = nil;
    self.player = nil;
    
    if ([self.delegate respondsToSelector:@selector(playerDidStop:)]) {
        [self.delegate playerDidStop:self];
    }
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if ([self.delegate respondsToSelector:@selector(playerDidStop:)]) {
        [self.delegate playerDidStop:self];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error
{
    if ([self.delegate respondsToSelector:@selector(playerWithError:)]) {
        [self.delegate playerWithError:error];
    }
}

@end
