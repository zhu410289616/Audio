//
//  CCDAudioUtil.h
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/12.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT AudioStreamBasicDescription CCDAudioCreateASBD_PCM16(NSInteger sampleRate, NSInteger channels);
FOUNDATION_EXPORT AudioStreamBasicDescription CCDAudioCreateASBD_PCM32(NSInteger sampleRate, NSInteger channels);
FOUNDATION_EXPORT AudioStreamBasicDescription CCDAudioCreateASBD_AAC(NSInteger sampleRate, NSInteger channels);
FOUNDATION_EXPORT AudioStreamBasicDescription CCDAudioCreateASBD_MP3(NSInteger sampleRate, NSInteger channels);

FOUNDATION_EXPORT void CCDAudioResetAudioBuffer(AudioBufferList *bufferList);
FOUNDATION_EXPORT void CCDAudioReleaseAudioBuffer(AudioBufferList *bufferList);

@interface CCDAudioUtil : NSObject

@end

NS_ASSUME_NONNULL_END
