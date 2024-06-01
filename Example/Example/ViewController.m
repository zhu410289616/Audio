//
//  ViewController.m
//  Example
//
//  Created by 十年之前 on 2024/5/6.
//

#import "ViewController.h"
#import "CCDRecorderView.h"

#import <CCDAudio/CCDAudioUtil.h>
#import <CCDAudio/CCDAudioSpectrumAnalyzer.h>

//player
#import <CCDAudio/CCDAVAudioPlayer.h>
#import <CCDAudio/CCDAVAudioPlayerInput.h>

#import <CCDAudio/CCDAUAudioPlayer.h>
#import <CCDAudio/CCDAudioPlayerInputPCM.h>
#import <CCDAudio/CCDAudioPlayerInputAAC.h>
#import <CCDAudio/CCDAudioPlayerInputMP3.h>

//recorder
#import <CCDAudio/CCDAVAudioRecorder.h>
#import <CCDAudio/CCDAVAudioRecorderOutput.h>

#import <CCDAudio/CCDAUAudioRecorder.h>
#import <CCDAudio/CCDAudioRecorderOutputPCM.h>
#import <CCDAudio/CCDAudioRecorderOutputMP3.h>
#import <CCDAudio/CCDAudioRecorderOutputM4A.h>
#import <CCDAudio/CCDAudioRecorderOutputAAC.h>

#import <CCDAudio/CCDAQAudioRecorder.h>
//#import <CCDAudio/CCDAQAudioRecorderSTOutput.h>
#import <CCDAudio/CCDAQAudioRecorderMP3Output.h>

//noise
#import "CCDTestNoiseProcessor.h"
#import <CCDAudio/CCDWebRTCNoiseProcessor.h>

typedef NS_ENUM(NSInteger, CCDAudioTestMenuType) {
    CCDAudioTestMenuTypeAudioPlay = 1,
    CCDAudioTestMenuTypeAVAudioRecorder,
    CCDAudioTestMenuTypeAQAudioRecorder,
    CCDAudioTestMenuTypeAUAudioRecorder,
    CCDAudioTestMenuTypeWebRTCNosieIn,
    CCDAudioTestMenuTypeWebRTCNosieOut,
    CCDAudioTestMenuTypeAACEncoder,
    CCDAudioTestMenuTypeAACDecoder,
    CCDAudioTestMenuTypeMP3Encoder,
    CCDAudioTestMenuTypeMP3Decoder,
    CCDAudioTestMenuTypeUnknown
};

@interface ViewController ()
<
UITableViewDelegate,
UITableViewDataSource,
CCDAudioRecorderDelegate,
CCDAudioPlayerDelegate
>

@property (nonatomic, strong) NSMutableArray *menuList;
@property (nonatomic, strong) CCDRecorderView *recorderView;

@property (nonatomic, strong) id<CCDAudioRecorderProvider> recorder;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) CADisplayLink *meterTimer;

@property (nonatomic, strong) id<CCDAudioPlayerProvider> player;

//音效
@property (nonatomic, assign) int fftSize;
@property (nonatomic, strong) CCDAudioSpectrumAnalyzer *spectrumAnalyzer;
@property (nonatomic, assign) NSTimeInterval lastRenderTime;

@end

@implementation ViewController

- (void)loadView {
    [super loadView];
    
    self.menuList = @[].mutableCopy;
    NSMutableDictionary *menuDic = nil;
    
    menuDic = @{
        @"menu_id": @(CCDAudioTestMenuTypeAudioPlay),
        @"content": @"play audio"
    }.mutableCopy;
    [self.menuList addObject:menuDic.mutableCopy];
    
    menuDic = @{
        @"menu_id": @(CCDAudioTestMenuTypeAVAudioRecorder),
        @"content": @"AVAudioRecorder"
    }.mutableCopy;
    [self.menuList addObject:menuDic];
    
    menuDic = @{
        @"menu_id": @(CCDAudioTestMenuTypeAQAudioRecorder),
        @"content": @"AQAudioRecorder"
    }.mutableCopy;
    [self.menuList addObject:menuDic];
    
    menuDic = @{
        @"menu_id": @(CCDAudioTestMenuTypeAUAudioRecorder),
        @"content": @"AUAudioRecorder"
    }.mutableCopy;
    [self.menuList addObject:menuDic];
    
    menuDic = @{
        @"menu_id": @(CCDAudioTestMenuTypeWebRTCNosieIn),
        @"content": @"录制 降噪测试 WebRTC"
    }.mutableCopy;
    [self.menuList addObject:menuDic];
    
    menuDic = @{
        @"menu_id": @(CCDAudioTestMenuTypeWebRTCNosieOut),
        @"content": @"播放 降噪测试 WebRTC"
    }.mutableCopy;
    [self.menuList addObject:menuDic];
    
    menuDic = @{
        @"menu_id": @(CCDAudioTestMenuTypeAACEncoder),
        @"content": @"PCM -> AAC 编码"
    }.mutableCopy;
    [self.menuList addObject:menuDic];
    
    menuDic = @{
        @"menu_id": @(CCDAudioTestMenuTypeAACDecoder),
        @"content": @"AAC -> PCM 解码"
    }.mutableCopy;
    [self.menuList addObject:menuDic];
    
    menuDic = @{
        @"menu_id": @(CCDAudioTestMenuTypeMP3Encoder),
        @"content": @"PCM -> MP3 编码"
    }.mutableCopy;
    [self.menuList addObject:menuDic];
    
    menuDic = @{
        @"menu_id": @(CCDAudioTestMenuTypeMP3Decoder),
        @"content": @"MP3 -> PCM 解码"
    }.mutableCopy;
    [self.menuList addObject:menuDic];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // spectrum analyzer
    self.fftSize = 2048;
    self.spectrumAnalyzer = [[CCDAudioSpectrumAnalyzer alloc] initWithFFTSize:self.fftSize];
    
    self.recorderView = [[CCDRecorderView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.recorderView];
    [self.recorderView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.size.equalTo(self.view);
    }];
    
    self.recorderView.tableView.delegate = self;
    self.recorderView.tableView.dataSource = self;
    Class cellClass = [UITableViewCell class];
    NSString *identifier = @"CCDTestTableViewCell";//NSStringFromClass(cellClass);
    [self.recorderView.tableView registerClass:cellClass forCellReuseIdentifier:identifier];
    [self.recorderView.tableView reloadData];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSMutableDictionary *menuDic = [self.menuList objectAtIndex:indexPath.row];
    NSInteger menuId = [menuDic[@"menu_id"] longLongValue];
    switch (menuId) {
        case CCDAudioTestMenuTypeAudioPlay:
            [self doPlayButtonAction];
            break;
        case CCDAudioTestMenuTypeAVAudioRecorder:
            [self doAVRecordButtonAction];
            break;
        case CCDAudioTestMenuTypeAQAudioRecorder:
            [self doAQRecordButtonAction];
            break;
        case CCDAudioTestMenuTypeAUAudioRecorder:
            [self doAURecordButtonAction];
            break;
        case CCDAudioTestMenuTypeWebRTCNosieIn:
            [self doRecorderWebRTCNoiseTest];
            break;
        case CCDAudioTestMenuTypeWebRTCNosieOut:
            [self doPlayerWebRTCNoiseTest];
            break;
        case CCDAudioTestMenuTypeAACEncoder:
            [self doAACRecordAction];
            break;
        case CCDAudioTestMenuTypeAACDecoder:
            [self doAACPlayAction];
            break;
        case CCDAudioTestMenuTypeMP3Encoder:
            [self doMP3RecordAction];
            break;
        case CCDAudioTestMenuTypeMP3Decoder:
            [self doMP3PlayAction];
            break;
        default:
            break;
    }//switch
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.menuList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *menuDic = [self.menuList objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CCDTestTableViewCell"];
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.textLabel.text = menuDic[@"content"];
    return cell;
}

#pragma mark - audio format

- (AudioStreamBasicDescription)pcmAudioFormat:(NSInteger)sampleRate
{
    AudioStreamBasicDescription audioFormat;
    //采样率，每秒钟抽取声音样本次数。根据奈奎斯特采样理论，为了保证声音不失真，采样频率应该在40kHz左右
    audioFormat.mSampleRate = sampleRate;
    audioFormat.mFormatID = kAudioFormatLinearPCM; //音频格式

    //详细描述了音频数据的数字格式，整数还是浮点数，大端还是小端
    //注意，如果是双声道，这里一定要设置kAudioFormatFlagIsNonInterleaved，否则初始化AudioUnit会出现错误 1718449215
    //kAudioFormatFlagIsNonInterleaved，非交错模式，即首先记录的是一个周期内所有帧的左声道样本，再记录所有右声道样本。
    //对应的认为交错模式，数据以连续帧的方式存放，即首先记录帧1的左声道样本和右声道样本，再开始帧2的记录。
    audioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsNonInterleaved;

    //下面就是设置声音采集时的一些值
    //比如采样率为44.1kHZ，采样精度为16位的双声道，可以算出比特率（bps）是44100*16*2bps，每秒的音频数据是固定的44100*16*2/8字节。
    //官方解释：满足下面这个公式时，上面的mFormatFlags会隐式设置为kAudioFormatFlagIsPacked
    //((mBitsPerSample / 8) * mChannelsPerFrame) == mBytesPerFrame
    audioFormat.mBytesPerPacket = 2;
    audioFormat.mFramesPerPacket = 1;
    audioFormat.mBytesPerFrame = 2;
    audioFormat.mChannelsPerFrame = 1;//1是单声道，2就是立体声。这里的数量决定了AudioBufferList的mBuffers长度是1还是2。
    audioFormat.mBitsPerChannel = 16;//采样位数，数字越大，分辨率越高。16位可以记录65536个数，一般来说够用了。

    return audioFormat;
}

#pragma mark - action

#pragma mark - MP3

- (void)doMP3RecordAction
{}

- (void)doMP3PlayAction
{
    if (self.player.isRunning) {
        [self.player stop];
        [self.recorderView updateStateInfo:@"player stop"];
    } else {
        NSURL *audioURL = [[NSBundle mainBundle] URLForResource:@"color_X_3D" withExtension:@"mp3"];//44100,2 解码正常
        
        if (self.filePath.length > 0) {
            audioURL = [NSURL fileURLWithPath:self.filePath];
        }
        
        NSString *ext = audioURL.pathExtension;
        id<CCDAudioPlayerInput> audioInput = nil;
        if ([ext isEqualToString:@"mp3"]) {
            CCDAudioPlayerInputMP3 *input = [[CCDAudioPlayerInputMP3 alloc] initWithURL:audioURL];
            audioInput = input;
            self.player = [[CCDAUAudioPlayer alloc] init];
        }
        
        self.player.delegate = self;
        self.player.audioInput = audioInput;
        if (![self.player prepare]) {
            CCDAudioLogE(@"player prepare failed");
            [self.recorderView updateStateInfo:@"player prepare failed"];
            return;
        }
        [self.player play];
        [self.recorderView updateStateInfo:@"player start"];
    }
}

#pragma mark - AAC

- (void)doAACRecordAction
{
    if (self.recorder.isRunning) {
        [self stopRecord];
        [self.recorderView updateStateInfo:@"AAC AudioUnit AudioRecorder stop"];
    } else {
        // m4a
        CCDAudioRecorderOutputAAC *output = [[CCDAudioRecorderOutputAAC alloc] init];
        [output setupAudioFormat:44100];
        
        [self setupAURecorder:output];
        [self startRecord];
        [self.recorderView updateStateInfo:@"AAC AudioUnit AudioRecorder start"];
    }
}

- (void)doAACPlayAction
{
    if (self.player.isRunning) {
        [self.player stop];
        [self.recorderView updateStateInfo:@"player stop"];
    } else {
        //ffplay -i /Users/shinianzhiqian/Desktop/pig/Audio/Example/Example/Resources/china-x.pcm -f s16le -ac 1 -ar 44100
        NSURL *audioURL = [[NSBundle mainBundle] URLForResource:@"video" withExtension:@"aac"];//44100,2 解码正常
//        NSURL *audioURL = [[NSBundle mainBundle] URLForResource:@"几个你_薛之谦" withExtension:@"aac"];//44100,2 解码异常
        
        if (self.filePath.length > 0) {
            audioURL = [NSURL fileURLWithPath:self.filePath];
        }
        
        NSString *ext = audioURL.pathExtension;
        id<CCDAudioPlayerInput> audioInput = nil;
        if ([ext isEqualToString:@"aac"]) {
            CCDAudioPlayerInputAAC *input = [[CCDAudioPlayerInputAAC alloc] initWithURL:audioURL];
            audioInput = input;
            
            CCDAUAudioPlayer *player = [[CCDAUAudioPlayer alloc] init];
            player.numberOfLoops = 2;
            @weakify(self);
            player.viewer = ^(AudioBufferList * _Nullable audioBufferList, NSInteger size) {
                @strongify(self);
                AudioStreamBasicDescription audioFormat = self.player.audioInput.audioFormat;
                [self updateSpectra:audioBufferList bufferSize:size audioFromat:audioFormat];
            };
            self.player = player;
        }
        
        self.player.delegate = self;
        self.player.audioInput = audioInput;
        if (![self.player prepare]) {
            CCDAudioLogE(@"player prepare failed");
            [self.recorderView updateStateInfo:@"player prepare failed"];
            return;
        }
        [self.player play];
        [self.recorderView updateStateInfo:@"player start"];
    }
}

#pragma mark - 降噪测试

- (void)doPlayerWebRTCNoiseTest
{
    if (self.player.isRunning) {
        [self.player stop];
        [self.recorderView updateStateInfo:@"player stop"];
    } else {
        //ffplay -i /Users/shinianzhiqian/Desktop/pig/Audio/Example/Example/Resources/china-x.pcm -f s16le -ac 1 -ar 44100
        NSURL *audioURL = [[NSBundle mainBundle] URLForResource:@"china-x" withExtension:@"pcm"];//44100
        NSInteger sampleRate = 44100;
        
//        NSURL *audioURL = [[NSBundle mainBundle] URLForResource:@"noise" withExtension:@"pcm"];//16000
//        NSInteger sampleRate = 16000;
        
        if (self.filePath.length > 0) {
            audioURL = [NSURL fileURLWithPath:self.filePath];
        }
        
        NSString *ext = audioURL.pathExtension;
        id<CCDAudioPlayerInput> audioInput = nil;
        if ([ext isEqualToString:@"pcm"]) {
            CCDAudioPlayerInputPCM *input = [[CCDAudioPlayerInputPCM alloc] initWithURL:audioURL];
            input.audioFormat = [self pcmAudioFormat:sampleRate];
            audioInput = input;
            self.player = [[CCDAUAudioPlayer alloc] init];
        } else if ([ext isEqualToString:@"aac"]) {
            CCDAudioPlayerInputAAC *input = [[CCDAudioPlayerInputAAC alloc] initWithURL:audioURL];
            audioInput = input;
            self.player = [[CCDAUAudioPlayer alloc] init];
        } else if ([ext isEqualToString:@"mp3"]
                   || [ext isEqualToString:@"m4a"]) {
            CCDAVAudioPlayerInput *input = [[CCDAVAudioPlayerInput alloc] init];
            input.audioPath = audioURL.path;
            audioInput = input;
            self.player = [[CCDAVAudioPlayer alloc] init];
        }
        
        self.player.delegate = self;
        self.player.audioInput = audioInput;
        if (![self.player prepare]) {
            CCDAudioLogE(@"player prepare failed");
            [self.recorderView updateStateInfo:@"player prepare failed"];
            return;
        }
        [self.player play];
        [self.recorderView updateStateInfo:@"player start"];
    }
}

- (void)doRecorderWebRTCNoiseTest
{
    if (self.recorder.isRunning) {
        [self stopRecord];
        [self.recorderView updateStateInfo:@"AudioUnit AudioRecorder stop"];
    } else {
        // pcm
        CCDTestNoiseProcessor *output = [[CCDTestNoiseProcessor alloc] initWithSampleRate:16000];
        [self setupAURecorder:output];
        [self startRecord];
        [self.recorderView updateStateInfo:@"AudioUnit AudioRecorder start"];
    }
}

#pragma mark - player

- (void)doPlayButtonAction
{
    if (self.player.isRunning) {
        [self.player stop];
        [self.recorderView updateStateInfo:@"player stop"];
    } else {
//        CCDAVAudioPlayerInput *input = [[CCDAVAudioPlayerInput alloc] init];
//        input.filePath = self.filePath;
//        self.player = [[CCDAVAudioPlayer alloc] init];
        
        //ffplay -i /Users/shinianzhiqian/Desktop/pig/Audio/Example/Example/Resources/china-x.pcm -f s16le -ac 1 -ar 44100
        NSURL *audioURL = [[NSBundle mainBundle] URLForResource:@"china-x" withExtension:@"pcm"];//44100
        NSInteger sampleRate = 44100;
        
//        NSURL *audioURL = [[NSBundle mainBundle] URLForResource:@"noise" withExtension:@"pcm"];//16000
//        NSInteger sampleRate = 16000;
        
        if (self.filePath.length > 0) {
            audioURL = [NSURL fileURLWithPath:self.filePath];
        }
        
        NSString *ext = audioURL.pathExtension;
        id<CCDAudioPlayerInput> audioInput = nil;
        if ([ext isEqualToString:@"pcm"]) {
            CCDAudioPlayerInputPCM *input = [[CCDAudioPlayerInputPCM alloc] initWithURL:audioURL];
            input.audioFormat = CCDAudioCreateASBD_PCM16(sampleRate, 1);
            audioInput = input;
            
            CCDAUAudioPlayer *player = [[CCDAUAudioPlayer alloc] init];
            player.numberOfLoops = 2;
            @weakify(self);
            player.viewer = ^(AudioBufferList * _Nullable audioBufferList, NSInteger size) {
                @strongify(self);
                AudioStreamBasicDescription audioFormat = self.player.audioInput.audioFormat;
                [self updateSpectra:audioBufferList bufferSize:size audioFromat:audioFormat];
            };
            self.player = player;
        } else if ([ext isEqualToString:@"mp3"]
                   || [ext isEqualToString:@"m4a"]) {
            CCDAVAudioPlayerInput *input = [[CCDAVAudioPlayerInput alloc] init];
            input.audioPath = audioURL.path;
            audioInput = input;
            self.player = [[CCDAVAudioPlayer alloc] init];
        }
        
        self.player.delegate = self;
        self.player.audioInput = audioInput;
        if (![self.player prepare]) {
            CCDAudioLogE(@"player prepare failed");
            [self.recorderView updateStateInfo:@"player prepare failed"];
            return;
        }
        [self.player play];
        [self.recorderView updateStateInfo:@"player start"];
    }
}

#pragma mark - recorder

- (void)doAURecordButtonAction
{
    if (self.recorder.isRunning) {
        [self stopRecord];
        [self.recorderView updateStateInfo:@"AudioUnit AudioRecorder stop"];
    } else {
        // pcm
//        CCDAudioRecorderOutputPCM *output = [[CCDAudioRecorderOutputPCM alloc] init];
//        output.audioFormat = [self pcmAudioFormat:44100];
        // mp3
//        CCDAudioRecorderOutputMP3 *output = [[CCDAudioRecorderOutputMP3 alloc] init];
//        [output setupAudioFormat:44100];
        // m4a
        CCDAudioRecorderOutputM4A *output = [[CCDAudioRecorderOutputM4A alloc] init];
        
        [self setupAURecorder:output];
        [self startRecord];
        [self.recorderView updateStateInfo:@"AudioUnit AudioRecorder start"];
    }
}

- (void)doAQRecordButtonAction
{
    if (self.recorder.isRunning) {
        [self stopRecord];
        [self.recorderView updateStateInfo:@"AudioQueue AudioRecorder stop"];
    } else {
        CCDAQAudioRecorderMP3Output *output = [[CCDAQAudioRecorderMP3Output alloc] init];
        [self setupAQRecorder:output];
        [self startRecord];
        [self.recorderView updateStateInfo:@"AudioQueue AudioRecorder start"];
    }
}

- (void)doAVRecordButtonAction
{
    if (self.recorder.isRunning) {
        [self stopRecord];
        [self.recorderView updateStateInfo:@"AVAudioRecorder stop"];
    } else {
        [self setupAVRecorder];
        [self startRecord];
        [self.recorderView updateStateInfo:@"AVAudioRecorder start"];
    }
}

#pragma mark - CCDAudioPlayerDelegate

- (void)playerWillStart:(id<CCDAudioPlayerProvider>)player
{
    CCDAudioLogD(@"playerWillStart");
    
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error) {
        CCDAudioLogE(@"playerWillStart error: %@", error);
    }
    
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (error) {
        CCDAudioLogE(@"playerWillStart error: %@", error);
    }
}

- (void)playerDidStop:(id<CCDAudioPlayerProvider>)player
{
    CCDAudioLogD(@"playerDidStop: %@", player.audioInput.audioPath);
    
    NSString *info = [NSString stringWithFormat:@"playerDidStop: %@", player.audioInput.audioPath];
    [self.recorderView updateStateInfo:info];
    self.filePath = nil;
    self.player = nil;
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

- (void)playerWithError:(NSError *)error
{
    CCDAudioLogD(@"playerWithError: %@", error);
    NSString *info = [NSString stringWithFormat:@"playerWithError: %@", error];
    [self.recorderView updateStateInfo:info];
}

#pragma mark - spectrum

- (void)updateSpectra:(AudioBufferList *)audioBufferList bufferSize:(NSInteger)bufferSize audioFromat:(AudioStreamBasicDescription)audioFormat
{
    double begintTime = CFAbsoluteTimeGetCurrent();
    if (begintTime - self.lastRenderTime < 0.1) {
        return;
    }
    self.lastRenderTime = begintTime;
    
    NSInteger bytesPerSample = audioFormat.mBytesPerFrame;
    NSInteger sampleRate = audioFormat.mSampleRate;//44100
    
    NSData *pcmData = [NSData dataWithBytes:audioBufferList->mBuffers[0].mData length:audioBufferList->mBuffers[0].mDataByteSize];
    /// 根据 位深 复制数据；
    /// 比如：单声道16位深度pcm数据 --> 双声道32位深度pcm数据；
    NSInteger pcmLength = pcmData.length / bytesPerSample;
    
    // 缓存 双声道32位深度pcm数据
    float stereoPcmBuffer[pcmLength];
    memset(&stereoPcmBuffer, 0, pcmLength);
    
    for (NSInteger i=0; i<pcmLength; i++) {
        short pcmValue = 0;
        NSRange valueRange = NSMakeRange(i*bytesPerSample, bytesPerSample);
//        NSData *valueData = [pcmData subdataWithRange:valueRange];
//        memcpy(&pcmValue, valueData.bytes, sizeof(pcmValue));
        [pcmData getBytes:&pcmValue range:valueRange];
        stereoPcmBuffer[i] = pcmValue;
    }
    
    AVAudioChannelLayout *channelLayout = [[AVAudioChannelLayout alloc] initWithLayoutTag:kAudioChannelLayoutTag_Stereo];
    AVAudioFormat *format = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:sampleRate interleaved:NO channelLayout:channelLayout];
    
    AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:2048];
    pcmBuffer.frameLength = pcmBuffer.frameCapacity;
    
    // 初始化数据区
    for (AVAudioChannelCount i=0; i<format.channelCount; i++) {
        memset(pcmBuffer.floatChannelData[i], 0, pcmBuffer.frameLength * format.streamDescription->mBytesPerFrame);
        memcpy(pcmBuffer.floatChannelData[i], &stereoPcmBuffer, pcmLength);
    }
    
    // pcm spectrum analyzer
    NSArray *spectrums = [self.spectrumAnalyzer analyse:pcmBuffer withAmplitudeLevel:0.2];//0.2 调整动画幅度
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.recorderView.spectrumView updateSpectra:spectrums withStype:CCDAudioSpectraStyleRound];
    });
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
//        self.meterTimer.frameInterval = 6;
    }
    [self.meterTimer addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)refreshMeter
{
    if (!self.recorder.meteringEnabled) {
        return;
    }
    float averagePower = [self.recorder averagePowerWithChannel:0];
    
    CGFloat normalizedValue = [self normalizedPowerLevelFromDecibels:averagePower];
    [self.recorderView.waveView updateWithLevel:normalizedValue];
    
    float ALPHA = 0.02f;
    float level = pow(10, (ALPHA *averagePower));
    if (level <= 0.05f) {
        level = 0.05f;
    } else if (level >= 1.0f) {
        level = 1.0f;
    }
    [self.recorderView.meterView updateLevelMeter:level];
}

- (CGFloat)normalizedPowerLevelFromDecibels:(CGFloat)decibels
{
    if (decibels < -60.0f || decibels == 0.0f) {
        return 0.0f;
    }
    
    return powf((powf(10.0f, 0.05f * decibels) - powf(10.0f, 0.05f * -60.0f)) * (1.0f / (1.0f - powf(10.0f, 0.05f * -60.0f))), 1.0f / 2.0f);
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
    CCDAUAudioRecorder *recorder = [[CCDAUAudioRecorder alloc] init];
    @weakify(self);
    recorder.viewer = ^(AudioBufferList * _Nullable audioBufferList, NSInteger size) {
        @strongify(self);
        AudioStreamBasicDescription audioFormat = self.recorder.audioOutput.audioFormat;
        [self updateSpectra:audioBufferList bufferSize:size audioFromat:audioFormat];
    };
    self.recorder = recorder;
    self.recorder.delegate = self;
    self.recorder.audioOutput = audioOutput;
}

- (void)startRecord
{
//    [self startMeterTimer];
    [self.recorder prepare];
    [self.recorder start];
}

- (void)stopRecord
{
    [self stopMeterTimer];
    [self.recorder stop];
    self.recorder.delegate = nil;
    self.recorder = nil;
}

#pragma mark - CCDAudioRecorderDelegate

- (void)recorderWillStart:(id<CCDAudioRecorderProvider>)recorder
{
    CCDAudioLogD(@"recorderWillStart");
    
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (error) {
        CCDAudioLogE(@"recorderWillStart error: %@", error);
    }
    
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (error) {
        CCDAudioLogE(@"recorderWillStart error: %@", error);
    }
}

- (void)recorderDidStart:(id<CCDAudioRecorderProvider>)recorder
{
    CCDAudioLogD(@"recorderDidStart");
}

- (void)recorderDidStop:(id<CCDAudioRecorderProvider>)recorder
{
    self.filePath = recorder.audioOutput.audioPath;
    CCDAudioLogD(@"recorderDidStop: %@", self.filePath);
    
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

- (void)recorderWithError:(NSError *)error
{
    CCDAudioLogE(@"recorderWithError: %@", error);
}

@end
