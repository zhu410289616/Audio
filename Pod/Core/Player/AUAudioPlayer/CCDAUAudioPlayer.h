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

@property (nonatomic, strong) id<CCDAudioPlayerDataInput> audioInput;
@property (nonatomic,   copy) CCDAudioUnitPlayCallback viewer;

@end

NS_ASSUME_NONNULL_END
