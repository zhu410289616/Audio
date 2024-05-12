//
//  ViewController.m
//  Example
//
//  Created by 十年之前 on 2024/5/6.
//

#import "ViewController.h"
#import "CCDRecorderView.h"

//player
#import <CCDAudio/CCDAVAudioPlayer.h>
#import <CCDAudio/CCDAVAudioPlayerInput.h>

#import <CCDAudio/CCDAUAudioPlayer.h>
#import <CCDAudio/CCDAudioPlayerInputPCM.h>

//recorder
#import <CCDAudio/CCDAVAudioRecorder.h>
#import <CCDAudio/CCDAVAudioRecorderOutput.h>

#import <CCDAudio/CCDAQAudioRecorder.h>
//#import <CCDAudio/CCDAQAudioRecorderSTOutput.h>
#import <CCDAudio/CCDAQAudioRecorderMP3Output.h>

#import <CCDAudio/CCDAUAudioRecorder.h>
#import <CCDAudio/CCDAUAudioRecorderMP3Output.h>

@interface ViewController ()
<
CCDAudioRecorderDelegate,
CCDAudioPlayerDelegate
>

@property (nonatomic, strong) CCDRecorderView *recorderView;

@property (nonatomic, strong) id<CCDAudioRecorderProvider> recorder;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) CADisplayLink *meterTimer;

@property (nonatomic, strong) id<CCDAudioPlayerProvider> player;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.recorderView = [[CCDRecorderView alloc] init];
    [self.view addSubview:self.recorderView];
    [self.recorderView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.size.equalTo(self.view);
    }];
    
    [self.recorderView.playButton addTarget:self action:@selector(doPlayButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.recorderView.soundTouchButton addTarget:self action:@selector(doSoundTouchButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.recorderView.recordButton addTarget:self action:@selector(doRecordButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.recorderView.mp3RecordButton addTarget:self action:@selector(doMp3RecordButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.recorderView.auRecordButton addTarget:self action:@selector(doAURecordButtonAction) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - action

- (void)doPlayButtonAction
{
    if (self.player.isRunning) {
        [self.player stop];
    } else {
//        CCDAVAudioPlayerInput *input = [[CCDAVAudioPlayerInput alloc] init];
//        input.filePath = self.filePath;
//        self.player = [[CCDAVAudioPlayer alloc] init];
        
//        NSURL *audioURL = [[NSBundle mainBundle] URLForResource:@"china-x" withExtension:@"pcm"];
        NSURL *audioURL = [[NSBundle mainBundle] URLForResource:@"noise" withExtension:@"pcm"];
        CCDAudioPlayerInputPCM *input = [[CCDAudioPlayerInputPCM alloc] initWithURL:audioURL];
        self.player = [[CCDAUAudioPlayer alloc] init];
        
        self.player.delegate = self;
        self.player.audioInput = input;
        if (![self.player prepare]) {
            CCDAudioLogE(@"audio unit prepare failed");
        }
        [self.player play];
    }
}

- (void)doSoundTouchButtonAction
{
//    if (self.recorder.isRunning) {
//        [self stopRecord];
//    } else {
//        CCDAQAudioRecorderSTOutput *output = [[CCDAQAudioRecorderSTOutput alloc] init];
//        output.pitchSemiTones = 8;
//        [self setupAQRecorder:output];
//        [self startRecord];
//    }
}

- (void)doRecordButtonAction
{
    [self doAVRecordButtonAction];
}

- (void)doAURecordButtonAction
{
    if (self.recorder.isRunning) {
        [self stopRecord];
    } else {
        CCDAUAudioRecorderMP3Output *output = [[CCDAUAudioRecorderMP3Output alloc] init];
        [self setupAURecorder:output];
        [self startRecord];
    }
}

- (void)doMp3RecordButtonAction
{
    if (self.recorder.isRunning) {
        [self stopRecord];
    } else {
        CCDAQAudioRecorderMP3Output *output = [[CCDAQAudioRecorderMP3Output alloc] init];
        [self setupAQRecorder:output];
        [self startRecord];
    }
}

- (void)doAVRecordButtonAction
{
    if (self.recorder.isRunning) {
        [self stopRecord];
    } else {
        [self setupAVRecorder];
        [self startRecord];
    }
}

#pragma mark - CCDAudioPlayerDelegate

- (void)playerWillStart:(id<CCDAudioPlayerProvider>)player
{
    CCDAudioLog(@"playerWillStart");
    
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error) {
        CCDAudioLog(@"playerWillStart error: %@", error);
    }
    
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (error) {
        CCDAudioLog(@"playerWillStart error: %@", error);
    }
}

- (void)playerDidStop:(id<CCDAudioPlayerProvider>)player
{
    CCDAudioLog(@"playerDidStop: %@", player.audioInput.audioPath);
    
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

- (void)playerWithError:(NSError *)error
{
    CCDAudioLog(@"playerWithError error: %@", error);
}

#pragma mark - meter

- (void)stopMeterTimer
{
    if (self.meterTimer) {
        [self.meterTimer invalidate];
        self.meterTimer = nil;
    }
}

- (void)startMeterTimer
{
    [self stopMeterTimer];
    
    self.meterTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(refreshMeter)];
    if (@available(iOS 10.0, *)) {
        self.meterTimer.preferredFramesPerSecond = 10;
    } else {
        self.meterTimer.frameInterval = 6;
    }
    [self.meterTimer addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)refreshMeter
{
    if (!self.recorder.meteringEnabled) {
        return;
    }
    float averagePower = [self.recorder averagePowerWithChannel:0];
    float ALPHA = 0.02f;
    float level = pow(10, (ALPHA *averagePower));
    if (level <= 0.05f) {
        level = 0.05f;
    } else if (level >= 1.0f) {
        level = 1.0f;
    }
    [self.recorderView.meterView updateLevelMeter:level];
}

#pragma mark - recorder

- (void)setupAVRecorder
{
    [self stopRecord];
    
    //AVRecoder
    self.recorder = [[CCDAVAudioRecorder alloc] init];
    self.recorder.delegate = self;
    self.recorder.audioOutput = [CCDAVAudioRecorderOutput cafAudioOutput];
}

- (void)setupAQRecorder:(id<CCDAudioRecorderOutput>)audioOutput
{
    [self stopRecord];
    
    //AQRecoder
    self.recorder = [[CCDAQAudioRecorder alloc] init];
    self.recorder.delegate = self;
    self.recorder.audioOutput = audioOutput;
}

- (void)setupAURecorder:(id<CCDAudioRecorderOutput>)audioOutput
{
    [self stopRecord];
    
    //AURecoder
    self.recorder = [[CCDAUAudioRecorder alloc] init];
    self.recorder.delegate = self;
    self.recorder.audioOutput = audioOutput;
}

- (void)startRecord
{
    [self startMeterTimer];
    [self.recorder prepareToRecord];
    [self.recorder startRecord];
}

- (void)stopRecord
{
    [self stopMeterTimer];
    [self.recorder stopRecord];
    self.recorder.delegate = nil;
    self.recorder = nil;
}

#pragma mark - CCDAudioRecorderDelegate

- (void)recorderWillStart:(id<CCDAudioRecorderProvider>)recorder
{
    CCDAudioLog(@"recorderWillStart");
    
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (error) {
        CCDAudioLog(@"recorderWillStart error: %@", error);
    }
    
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (error) {
        CCDAudioLog(@"recorderWillStart error: %@", error);
    }
}

- (void)recorderDidStart:(id<CCDAudioRecorderProvider>)recorder
{
    CCDAudioLog(@"recorderDidStart");
}

- (void)recorderDidStop:(id<CCDAudioRecorderProvider>)recorder
{
    self.filePath = recorder.audioOutput.filePath;
    CCDAudioLog(@"recorderDidStop: %@", self.filePath);
    
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

- (void)recorderWithError:(NSError *)error
{
    CCDAudioLog(@"recorderWithError: %@", error);
}

@end
