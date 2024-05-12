//
//  CCDAUAudioPlayer.h
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/12.
//

#import <Foundation/Foundation.h>
#import "CCDAudioPlayerProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface CCDAUAudioPlayer : NSObject <CCDAudioPlayerProvider>

@property (nonatomic, strong) id<CCDAudioPlayerFormatInput> audioInput;

@end

NS_ASSUME_NONNULL_END
