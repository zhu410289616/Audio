//
//  CCDAQAudioRecorderMP3Output.h
//  Cicada
//
//  Created by ruhong zhu on 2020/6/20.
//

#import <Foundation/Foundation.h>
#import "CCDAudioRecorderOutput.h"

NS_ASSUME_NONNULL_BEGIN

/**
*  一般使用采样率 8000 缓冲区秒数为0.5
*/
@interface CCDAQAudioRecorderMP3Output : NSObject <CCDAudioQueueRecorderOutput>

@end

NS_ASSUME_NONNULL_END
