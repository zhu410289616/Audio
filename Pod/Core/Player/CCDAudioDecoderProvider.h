//
//  CCDAudioDecoderProvider.h
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/26.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CCDAudioDecoderProvider <NSObject>

@property (nonatomic, assign) AudioStreamBasicDescription inASBD;
@property (nonatomic, assign) AudioStreamBasicDescription outASBD;

- (void)setup;
- (void)cleanup;

- (AudioBufferList *)decodeRawData:(NSData *)rawData;

@end

NS_ASSUME_NONNULL_END
