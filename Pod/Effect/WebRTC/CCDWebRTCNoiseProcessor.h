//
//  CCDWebRTCNoiseProcessor.h
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/18.
//
// https://github.com/BeWithU/AudioUnitManager

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCDWebRTCNoiseProcessor : NSObject

/// WebRTC降噪处理只支持 10s、30s、60s；
/// 降噪强度 mode：0-mild，1-medium，2-aggressive；
- (instancetype)initWithSampleRate:(NSInteger)sampleRate mode:(int)mode;

/// 处理需要降噪的数据；如果传入的数据小于10ms，则返回空；
- (NSData *)nsProcess:(NSData *)pcmData;

@end

NS_ASSUME_NONNULL_END
