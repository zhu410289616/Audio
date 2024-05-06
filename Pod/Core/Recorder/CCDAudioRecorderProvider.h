//
//  CCDAudioRecorderProvider.h
//  Cicada
//
//  Created by ruhong zhu on 2020/6/13.
//

#import <Foundation/Foundation.h>
#import "CCDAudioRecorderOutput.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CCDAudioRecorderProvider;

#pragma mark -

@protocol CCDAudioRecorderDelegate <NSObject>

@optional

- (void)recorderWillStart:(id<CCDAudioRecorderProvider>)recorder;
- (void)recorderDidStart:(id<CCDAudioRecorderProvider>)recorder;

- (void)recorderDidStop:(id<CCDAudioRecorderProvider>)recorder;

- (void)recorderWithError:(NSError *)error;

@end

#pragma mark -

@protocol CCDAudioRecorderProvider <NSObject>

@required

@property (nonatomic,   weak) id<CCDAudioRecorderDelegate> delegate;
@property (nonatomic, strong) id<CCDAudioRecorderOutput> audioOutput;
@property (nonatomic, assign) BOOL isRunning;

- (BOOL)prepareToRecord;

- (void)startRecord;
- (void)stopRecord;

@optional

@property (nonatomic, assign) BOOL meteringEnabled;
- (float)averagePowerWithChannel:(int)channel;

@end

NS_ASSUME_NONNULL_END
