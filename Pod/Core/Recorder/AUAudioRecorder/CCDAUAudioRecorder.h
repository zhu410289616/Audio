//
//  CCDAUAudioRecorder.h
//  Pods
//
//  Created by 十年之前 on 2023/7/31.
//

#import <Foundation/Foundation.h>
#import "CCDAudioRecorderProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface CCDAUAudioRecorder : NSObject <CCDAudioRecorderProvider>

@property (nonatomic, strong) id<CCDAudioRecorderDataOutput> audioOutput;

@end

NS_ASSUME_NONNULL_END
