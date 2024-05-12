//
//  CCDAudioPlayerInput.h
//  Cicada
//
//  Created by ruhong zhu on 2020/6/19.
//

#import <Foundation/Foundation.h>
#import "CCDAudioDefines.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^CCDAudioDataCallback)(void * _Nullable bytes, NSInteger size);

@protocol CCDAudioPlayerInput <NSObject>

@required

@property (nonatomic, strong) NSString *audioPath;

@end

@protocol CCDAudioPlayerFormatInput <CCDAudioPlayerInput>

@property (nonatomic, assign) AudioStreamBasicDescription audioFormat;

- (void)begin;
- (void)end;

- (void)read:(CCDAudioDataCallback)callback maxSize:(NSInteger)maxSize;

@end

NS_ASSUME_NONNULL_END
