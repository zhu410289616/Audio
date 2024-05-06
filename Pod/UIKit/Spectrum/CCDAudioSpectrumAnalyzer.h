//
//  RealtimeAnalyzer.h
//  AudioSpectrumDemo
//
//  Created by user on 2019/5/16.
//  Copyright © 2019 adu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCDAudioBandsInfo : NSObject

@property (nonatomic, assign) float lowerFrequency;
@property (nonatomic, assign) float upperFrequency;

+ (instancetype)createWith:(float)lowerFrequency upperFrequency:(float)upperFrequency;

@end

FOUNDATION_EXPORT NSArray *CCDASCreateFrequencyWeights(float frequency, int fftSize);
FOUNDATION_EXPORT NSArray *CCDAudioSpectrumFFT(AVAudioPCMBuffer *buffer, FFTSetup fftSetup, int fftSize);
FOUNDATION_EXPORT float CCDASFindMaxAmplitude(CCDAudioBandsInfo *band, NSArray *amplitudes, float bandWidth);
//使用加权平均, 消除锯齿过多，使波形更明显
FOUNDATION_EXPORT NSMutableArray *CCDASHighlightWaveform(NSArray *spectrum);

@interface CCDAudioSpectrumAnalyzer : NSObject

- (instancetype)initWithFFTSize:(int)fftSize;
- (NSArray *)analyse:(AVAudioPCMBuffer *)buffer withAmplitudeLevel:(int)amplitudeLevel;

@end

NS_ASSUME_NONNULL_END
