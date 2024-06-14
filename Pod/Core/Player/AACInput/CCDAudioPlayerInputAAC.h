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

@property (nonatomic, copy) CCDAudioBufferListCallback aacCallback;

- (instancetype)initWithURL:(NSURL *)audioURL;

@end

NS_ASSUME_NONNULL_END
