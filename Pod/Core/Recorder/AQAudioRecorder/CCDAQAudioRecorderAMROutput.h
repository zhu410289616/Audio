//
//  CCDAQAudioRecorderAMROutput.h
//  Cicada
//
//  Created by ruhong zhu on 2020/6/20.
//

#import <Foundation/Foundation.h>
#import "CCDAudioRecorderOutput.h"

NS_ASSUME_NONNULL_BEGIN

/**
*  采样率必须为8000，然后缓冲区秒数必须为0.02的倍数。
*/
@interface CCDAQAudioRecorderAMROutput : NSObject <CCDAudioQueueRecorderOutput>

@end

NS_ASSUME_NONNULL_END
