//
//  CCDTestNoiseProcessor.h
//  Example
//
//  Created by 十年之前 on 2024/5/18.
//

#import <Foundation/Foundation.h>
#import <CCDAudio/CCDAudioRecorderOutputPCM.h>
#import <CCDAudio/CCDWebRTCNoiseProcessor.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCDTestNoiseProcessor : CCDAudioRecorderOutputPCM

@property (nonatomic, strong) CCDWebRTCNoiseProcessor *processor;

@end

NS_ASSUME_NONNULL_END
