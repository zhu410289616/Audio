//
//  CCDAVPlayer.m
//  AFNetworking
//
//  Created by ruhong zhu on 2020/9/5.
//

#import "CCDAVPlayer.h"

@interface CCDAVPlayer () <AVAssetResourceLoaderDelegate>

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) id timeObserver;

@property (nonatomic, strong) AVURLAsset *asset;

@end

@implementation CCDAVPlayer

@synthesize delegate;
@synthesize audioInput;
@synthesize isRunning;
@dynamic volume;

#pragma mark - CCDAudioPlayerProvider

- (void)setVolume:(float)volume
{
    self.player.volume = volume;
}

- (float)volume
{
    return self.player.volume;
}

- (BOOL)prepareToPlay
{
    if ([self.delegate respondsToSelector:@selector(playerWillStart:)]) {
        [self.delegate playerWillStart:self];
    }
    
    NSString *filePath = self.audioInput.filePath;
    CCDAudioLog(@"filePath: %@", filePath);
    if (filePath.length == 0) {
        return NO;
    }
    NSURL *audioFileURL = [NSURL fileURLWithPath:filePath];
    if ([filePath hasPrefix:@"http://"]
        || [filePath hasPrefix:@"https://"]) {
        audioFileURL = [NSURL URLWithString:filePath];
        //边下载边播放
        self.asset = [AVURLAsset URLAssetWithURL:audioFileURL options:nil];
        [self.asset.resourceLoader setDelegate:self queue:dispatch_get_main_queue()];
    }
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:audioFileURL];
    NSError *error = nil;
    self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    if ((error || nil == self.player)
        && [self.delegate respondsToSelector:@selector(playerWithError:)]) {
        [self.delegate playerWithError:error];
        return NO;
    }
    
//    self.player.delegate = self;
    return YES;
}

- (void)startPlay
{
    [self.player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.player.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playFinish) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    __weak typeof(self) weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        __strong typeof(self) strongSelf = weakSelf;
        NSLog(@"duration: %f, seconds: %f", CMTimeGetSeconds(strongSelf.player.currentItem.duration), CMTimeGetSeconds(time));
    }];
    [self.player play];
    self.isRunning = YES;
    
    if ([self.delegate respondsToSelector:@selector(playerDidStart:)]) {
        [self.delegate playerDidStart:self];
    }
}

- (void)stopPlay
{
    if (!self.isRunning || !self.player) {
        return;
    }
    
    self.isRunning = NO;
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [self.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
    [self.player pause];
//    self.player.delegate = nil;
    self.player = nil;
    
    if ([self.delegate respondsToSelector:@selector(playerDidStop:)]) {
        [self.delegate playerDidStop:self];
    }
}

#pragma mark - observer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = [change[NSKeyValueChangeNewKey] integerValue];
        switch (status) {
            case AVPlayerItemStatusUnknown:
            case AVPlayerItemStatusFailed: {
                CCDAudioLog(@"item failed ...");
            }
                break;
            case AVPlayerItemStatusReadyToPlay: {
                [self.player play];
            }
                break;
                
            default:
                break;
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSArray *array = self.player.currentItem.loadedTimeRanges;
        // 本次缓冲的时间范围
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        // 缓冲总长度
        NSTimeInterval totalBuffer = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration);
        // 音乐的总时间
        NSTimeInterval duration = CMTimeGetSeconds(self.player.currentItem.duration);
        // 计算缓冲百分比例
        NSTimeInterval scale = totalBuffer / duration;
        //
        NSLog(@"总时长：%f, 已缓冲：%f, 总进度：%f", duration, totalBuffer, scale);
    }
}

- (void)playFinish
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerDidStop:)]) {
        [self.delegate playerDidStop:self];
    }
}

#pragma mark - AVAssetResourceLoaderDelegate

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest
{
    return NO;
}

/*!
 @method         resourceLoader:shouldWaitForRenewalOfRequestedResource:
 @abstract        Invoked when assistance is required of the application to renew a resource.
 @param         resourceLoader
 The instance of AVAssetResourceLoader for which the loading request is being made.
 @param         renewalRequest
 An instance of AVAssetResourceRenewalRequest that provides information about the requested resource.
 @result         YES if the delegate can renew the resource indicated by the AVAssetResourceLoadingRequest; otherwise NO.
 @discussion
 Delegates receive this message when assistance is required of the application to renew a resource previously loaded by resourceLoader:shouldWaitForLoadingOfRequestedResource:. For example, this method is invoked to renew decryption keys that require renewal, as indicated in a response to a prior invocation of resourceLoader:shouldWaitForLoadingOfRequestedResource:.
 If the result is YES, the resource loader expects invocation, either subsequently or immediately, of either -[AVAssetResourceRenewalRequest finishLoading] or -[AVAssetResourceRenewalRequest finishLoadingWithError:]. If you intend to finish loading the resource after your handling of this message returns, you must retain the instance of AVAssetResourceRenewalRequest until after loading is finished.
 If the result is NO, the resource loader treats the loading of the resource as having failed.
 Note that if the delegate's implementation of -resourceLoader:shouldWaitForRenewalOfRequestedResource: returns YES without finishing the loading request immediately, it may be invoked again with another loading request before the prior request is finished; therefore in such cases the delegate should be prepared to manage multiple loading requests.
 
  If an AVURLAsset is added to an AVContentKeySession object and a delegate is set on its AVAssetResourceLoader, that delegate's resourceLoader:shouldWaitForRenewalOfRequestedResource:renewalRequest method must specify which custom URL requests should be handled as content keys. This is done by returning YES and passing either AVStreamingKeyDeliveryPersistentContentKeyType or AVStreamingKeyDeliveryContentKeyType into -[AVAssetResourceLoadingContentInformationRequest setContentType:] and then calling -[AVAssetResourceLoadingRequest finishLoading].
*/
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForRenewalOfRequestedResource:(AVAssetResourceRenewalRequest *)renewalRequest
{
    return NO;
}

/*!
 @method         resourceLoader:didCancelLoadingRequest:
 @abstract        Informs the delegate that a prior loading request has been cancelled.
 @param         loadingRequest
                The loading request that has been cancelled.
 @discussion    Previously issued loading requests can be cancelled when data from the resource is no longer required or when a loading request is superseded by new requests for data from the same resource. For example, if to complete a seek operation it becomes necessary to load a range of bytes that's different from a range previously requested, the prior request may be cancelled while the delegate is still handling it.
*/
- (void)resourceLoader:(AVAssetResourceLoader *)resourceLoader didCancelLoadingRequest:(AVAssetResourceLoadingRequest *)loadingRequest
{}

@end
