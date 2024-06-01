//
//  CCDAudioRecorderOutputPCM.h
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/12.
//

#import <Foundation/Foundation.h>
#import "CCDAudioRecorderOutput.h"

NS_ASSUME_NONNULL_BEGIN

@interface CCDAudioRecorderOutputPCM : NSObject <CCDAudioRecorderDataOutput>

@property (nonatomic, copy) CCDAudioBufferListCallback pcmCallback;

- (void)write:(void *)bytes maxSize:(NSInteger)maxSize;

@end

NS_ASSUME_NONNULL_END
