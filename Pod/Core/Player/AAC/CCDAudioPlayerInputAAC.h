//
//  CCDAudioPlayerInputAAC.h
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/20.
//

#import <Foundation/Foundation.h>
#import "CCDAudioPlayerInput.h"

NS_ASSUME_NONNULL_BEGIN

@interface CCDAudioPlayerInputAAC : NSObject <CCDAudioPlayerDataInput>

- (instancetype)initWithURL:(NSURL *)audioURL;

@end

NS_ASSUME_NONNULL_END
