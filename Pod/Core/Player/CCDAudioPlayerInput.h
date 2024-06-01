//
//  CCDAudioPlayerInput.h
//  Cicada
//
//  Created by ruhong zhu on 2020/6/19.
//

#import <Foundation/Foundation.h>
#import "CCDAudioDefines.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^CCDAudioUnitPlayCallback)(AudioBufferList * _Nullable inAudioBufferList, NSInteger inSize);
typedef void(^CCDAudioPlayerInCallback)(void * _Nullable bytes, NSInteger size);

@protocol CCDAudioPlayerInput <NSObject>

@required

@property (nonatomic, strong) NSString *audioPath;

@end

@protocol CCDAudioPlayerDataInput <CCDAudioPlayerInput>

@property (nonatomic, assign) AudioStreamBasicDescription audioFormat;

- (void)begin;
- (void)end;

- (void)input:(CCDAudioUnitPlayCallback)callback bufferSize:(NSInteger)bufferSize;
- (void)read:(CCDAudioPlayerInCallback)callback maxSize:(NSInteger)maxSize;

@end

NS_ASSUME_NONNULL_END
