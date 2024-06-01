//
//  CCDPushStreamRTMP.h
//  Pods
//
//  Created by 十年之前 on 2023/6/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCDPushStreamRTMP : NSObject

@property (nonatomic, assign) BOOL isRunning;

- (BOOL)connectWith:(NSString *)urlString;
- (void)disconnect;

/// 发送视频sps，pps
- (void)sendVideoSps:(NSData *)spsData pps:(NSData *)ppsData;
/// 发送视频帧数据
- (void)sendVideoData:(NSData *)data isKeyFrame:(BOOL)isKeyFrame;
/// 发送音频头信息
- (void)sendAudioHeader:(NSData *)data;
/// 发送音频数据
- (void)sendAudioData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
