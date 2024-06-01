//
//  CCDAudioEncoderProvider.h
//  CCDAudio
//
//  Created by 十年之前 on 2024/6/1.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CCDAudioEncoderProvider <NSObject>

@property (nonatomic, assign) AudioStreamBasicDescription inASBD;
@property (nonatomic, assign) AudioStreamBasicDescription outASBD;

- (void)cleanup;
- (void)setup;

- (void)encodeRawData:(NSData *)rawData completion:(void (^)(AudioBufferList *outAudioBufferList))completion;

@end

NS_ASSUME_NONNULL_END
