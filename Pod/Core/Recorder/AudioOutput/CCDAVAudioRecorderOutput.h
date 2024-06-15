//
//  CCDAVAudioRecorderOutput.h
//  Cicada
//
//  Created by ruhong zhu on 2020/6/14.
//

#import <Foundation/Foundation.h>
#import "CCDAudioRecorderOutput.h"

NS_ASSUME_NONNULL_BEGIN

@interface CCDAVAudioRecorderOutput : NSObject <CCDAudioRecorderDataOutput>

+ (instancetype)m4aAudioOutput;
+ (instancetype)cafAudioOutput;

@end

NS_ASSUME_NONNULL_END
