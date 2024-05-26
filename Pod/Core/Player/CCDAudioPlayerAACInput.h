//
//  CCDAudioPlayerAACInput.h
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/26.
//

#import <Foundation/Foundation.h>
#import "CCDAudioPlayerInput.h"

NS_ASSUME_NONNULL_BEGIN

@interface CCDAudioPlayerAACInput : NSObject <CCDAudioPlayerDataInput>

- (instancetype)initWithURL:(NSURL *)audioURL;

@end

NS_ASSUME_NONNULL_END
