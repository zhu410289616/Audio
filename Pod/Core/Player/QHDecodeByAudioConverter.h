//
//  QHDecodeByAudioConverter.h
//  QHAudioConverterMan
//
//  Created by Anakin chen on 2021/4/13.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "CCDAudioDecoderProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface QHDecodeByAudioConverter : NSObject <CCDAudioDecoderProvider>

- (AudioBufferList *)decodeAudioSamepleBuffer:(NSData *)data;
- (void)close;

@end

NS_ASSUME_NONNULL_END
