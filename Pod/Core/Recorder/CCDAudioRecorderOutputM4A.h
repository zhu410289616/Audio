//
//  CCDAudioRecorderOutputM4A.h
//  CCDAudio
//
//  Created by zhuruhong on 2024/5/17.
//

#import <Foundation/Foundation.h>
#import "CCDAudioRecorderOutput.h"

NS_ASSUME_NONNULL_BEGIN

@interface CCDAudioRecorderOutputM4A : NSObject <CCDAudioRecorderDataOutput>

- (void)setupAudioFormat:(NSInteger)sampleRate;

@end

NS_ASSUME_NONNULL_END
