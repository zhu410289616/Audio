//
//  CCDAudioPlayerInput.h
//  Cicada
//
//  Created by ruhong zhu on 2020/6/19.
//

#import <Foundation/Foundation.h>
#import "CCDAudioDefines.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^CCDAudioPlayerInCallback)(void * _Nullable bytes, NSInteger size);

@protocol CCDAudioPlayerInput <NSObject>

@required

@property (nonatomic, strong) NSString *audioPath;
@property (nonatomic, assign) AudioStreamBasicDescription audioFormat;

@end

@protocol CCDAudioPlayerDataInput <CCDAudioPlayerInput>

- (void)begin;
- (void)end;

- (void)input:(CCDAudioBufferListCallback)callback bufferSize:(NSInteger)bufferSize;

@end

NS_ASSUME_NONNULL_END
