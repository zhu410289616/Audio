//
//  CCDAudioRecorderOutputAAC.h
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/18.
//
// https://zhuanlan.zhihu.com/p/514352313

#import <Foundation/Foundation.h>
#import "CCDAudioRecorderOutput.h"

NS_ASSUME_NONNULL_BEGIN

@interface CCDAudioRecorderOutputAAC : NSObject <CCDAudioRecorderDataOutput>

@property (nonatomic, copy) CCDAudioBufferListCallback aacCallback;

- (void)setupAudioFormat:(NSInteger)sampleRate;

@end

NS_ASSUME_NONNULL_END
