//
//  CCDAudioPlayerInputMP3.h
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/31.
//

#import <Foundation/Foundation.h>
#import "CCDAudioPlayerInput.h"

NS_ASSUME_NONNULL_BEGIN

@interface CCDAudioPlayerInputMP3 : NSObject <CCDAudioPlayerDataInput>

- (instancetype)initWithURL:(NSURL *)audioURL;

@end

NS_ASSUME_NONNULL_END
