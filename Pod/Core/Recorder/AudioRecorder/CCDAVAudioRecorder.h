//
//  CCDAVAudioRecorder.h
//  Cicada
//
//  Created by ruhong zhu on 2020/6/13.
//

#import <Foundation/Foundation.h>
#import "CCDAudioRecorderProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface CCDAVAudioRecorder : NSObject <CCDAudioRecorderProvider>

@property (nonatomic, strong) id<CCDAudioRecorderDataOutput> audioOutput;

@end

NS_ASSUME_NONNULL_END
