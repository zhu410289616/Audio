//
//  CCDAQAudioRecorder.h
//  Cicada
//
//  Created by ruhong zhu on 2020/6/13.
//

#import <Foundation/Foundation.h>
#import "CCDAudioRecorderProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface CCDAQAudioRecorder : NSObject <CCDAudioRecorderProvider>

@property (nonatomic, strong) id<CCDAudioQueueRecorderOutput> audioOutput;

@end

NS_ASSUME_NONNULL_END
