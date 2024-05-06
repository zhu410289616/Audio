//
//  CCDAudioPlayerProvider.h
//  Cicada
//
//  Created by ruhong zhu on 2020/6/14.
//

#import <Foundation/Foundation.h>
#import "CCDAudioPlayerInput.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CCDAudioPlayerProvider;

#pragma mark -

@protocol CCDAudioPlayerDelegate <NSObject>

@optional

- (void)playerWillStart:(id<CCDAudioPlayerProvider>)player;
- (void)playerDidStart:(id<CCDAudioPlayerProvider>)player;
- (void)playerDidStop:(id<CCDAudioPlayerProvider>)player;
- (void)playerWithError:(NSError *)error;

@end

#pragma mark -

@protocol CCDAudioPlayerProvider <NSObject>

@required

@property (nonatomic,   weak) id<CCDAudioPlayerDelegate> delegate;
@property (nonatomic, strong) id<CCDAudioPlayerInput> audioInput;
@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, assign) float volume;
@property (nonatomic, assign) NSInteger numberOfLoops;

- (BOOL)prepareToPlay;

- (void)startPlay;
- (void)stopPlay;

@end

NS_ASSUME_NONNULL_END
