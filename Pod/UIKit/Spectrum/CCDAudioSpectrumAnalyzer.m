//
//  RealtimeAnalyzer.m
//  AudioSpectrumDemo
//
//  Created by user on 2019/5/16.
//  Copyright © 2019 adu. All rights reserved.
//

#import "CCDAudioSpectrumAnalyzer.h"

@implementation CCDAudioBandsInfo

+ (instancetype)createWith:(float)lowerFrequency upperFrequency:(float)upperFrequency {
    CCDAudioBandsInfo *info = [[CCDAudioBandsInfo alloc] init];
    info.lowerFrequency = lowerFrequency;
    info.upperFrequency = upperFrequency;
    return info;
}

@end

@interface CCDAudioSpectrumAnalyzer ()

@property (nonatomic, assign) float spectrumSmooth;
/** 音频频率 */
@property (nonatomic, assign) float frequency;
@property (nonatomic, assign) int fftSize;
/** 频带数量 */
@property (nonatomic, assign) NSUInteger frequencyBands;
/** 起始帧率 */
@property (nonatomic, assign) float startFrequency;
/** 截止帧率 */
@property (nonatomic, assign) float endFrequency;

@property (nonatomic, assign) FFTSetup fftSetup;
@property (nonatomic, strong) NSMutableArray *spectrumBuffer;
@property (nonatomic, strong) NSArray *aWeights;
@property (nonatomic, strong) NSArray *bands;


@end
@implementation CCDAudioSpectrumAnalyzer

- (void)dealloc {
    if (self.fftSetup != NULL) {
        vDSP_destroy_fftsetup(self.fftSetup);
        self.fftSetup = NULL;
    }
}

- (instancetype)initWithFFTSize:(int)fftSize {
    if (self == [super init]) {
        _frequency = 44100.0;
        _fftSize = fftSize;
        [self comminit];
    }
    return self;
}

- (void)comminit {
    self.frequencyBands = 80;
    self.startFrequency = 100.0;
    self.endFrequency = 18000.0;
    self.spectrumSmooth = 0.5; //缓动系数，数值越大动画越"缓"
    self.fftSetup = vDSP_create_fftsetup((vDSP_Length)(round(log2(self.fftSize))), kFFTRadix2);
    
    self.spectrumBuffer = [NSMutableArray array];
    for (NSUInteger i = 0; i < 2; i++) {
        NSMutableArray *arr = [NSMutableArray array];
        for (int j = 0; j < self.frequencyBands; j++) {
            [arr addObject: [NSNumber numberWithFloat:0.0]];
        }
        [self.spectrumBuffer addObject:arr];
    }
    
    NSMutableArray *tmps = [NSMutableArray array];
    //1：根据起止频谱、频带数量确定增长的倍数：2^n
    float n = log2f(self.endFrequency / self.startFrequency) / (self.frequencyBands * 1.0);
    float frequencyPowf = powf(2, n);
    CCDAudioBandsInfo *first = [CCDAudioBandsInfo createWith:self.startFrequency upperFrequency:0];
    for (int i = 1; i <= self.frequencyBands; i++) {
        float highFrequency = first.lowerFrequency * frequencyPowf;
        float upperFrequency = i == self.frequencyBands ? self.endFrequency : highFrequency;
        first.upperFrequency = upperFrequency;
        [tmps addObject:[CCDAudioBandsInfo createWith:first.lowerFrequency upperFrequency:first.upperFrequency]];
        first.lowerFrequency = highFrequency;
    }
    self.bands = [NSArray arrayWithArray:tmps];
    
    //创建权重数组
    self.aWeights = CCDASCreateFrequencyWeights(self.frequency, self.fftSize);
}
#pragma mark - override getter or setter
- (void)setSpectrumSmooth:(float)spectrumSmooth {
    _spectrumSmooth = MAX(0.0, spectrumSmooth);
    _spectrumSmooth = MIN(1.0, _spectrumSmooth);
}

#pragma mark - privte method

#pragma mark - public method
- (NSArray *)analyse:(AVAudioPCMBuffer *)buffer withAmplitudeLevel:(float)amplitudeLevel {
    float bandWidth = (float)buffer.format.sampleRate / (float)(self.fftSize * 1.0);
    NSArray *channelsAmplitudes = CCDAudioSpectrumFFT(buffer, self.fftSetup, self.fftSize);
    NSUInteger count = channelsAmplitudes.count;//2
    
    NSMutableArray *tempSpectrumBuffer = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < count; i++) {
        NSArray *amplitudes = channelsAmplitudes[i];
        NSUInteger subCount = amplitudes.count;
        NSMutableArray *weightedAmplitudes = [[NSMutableArray alloc] initWithCapacity:10];
        for (NSUInteger j = 0; j < subCount; j++) {
            //2：原始频谱数据依次与权重相乘
            float weighted = [amplitudes[j] floatValue] * [self.aWeights[j] floatValue];
            [weightedAmplitudes addObject: [NSNumber numberWithFloat:weighted]];
        }
        
        //3: findMaxAmplitude函数将从新的`weightedAmplitudes`中查找最大值
        NSMutableArray *spectrum = [[NSMutableArray alloc] initWithCapacity:10];
        for (int t = 0; t < self.frequencyBands; t++) {
//            float bandWidth = (float)buffer.format.sampleRate / (float)(self.fftSize * 1.0);
            float result = CCDASFindMaxAmplitude(self.bands[t], weightedAmplitudes, bandWidth) * amplitudeLevel; //amplitudeLevel 调整动画幅度
            [spectrum addObject: [NSNumber numberWithFloat:result]];
        }
        
        //4：添加到数组之前调用highlightWaveform
        spectrum = CCDASHighlightWaveform(spectrum);
        
        //5: 结合旧数据计算新状态数据
        NSMutableArray *lastFrequencyBands = self.spectrumBuffer[i];
        NSMutableArray *tempFrequencyBands = [[NSMutableArray alloc] initWithCapacity:10];
        for (int t = 0; t < self.frequencyBands; t++) {
//            float oldVal = [self.spectrumBuffer[i][t] floatValue];
            float oldVal = [lastFrequencyBands[t] floatValue];
            float newVal = [spectrum[t] floatValue];
            float result = oldVal * self.spectrumSmooth + newVal * (1.0 - self.spectrumSmooth);
            // 数组操作非线程安全；analyzer 和 spectrum 渲染在不同线程存在并发问题；
//            self.spectrumBuffer[i][t] = [NSNumber numberWithFloat:(isnan(result) ? 0 : result)];
            [tempFrequencyBands addObject:@(isnan(result) ? 0 : result)];
        }
        [tempSpectrumBuffer addObject:tempFrequencyBands];
    }
    self.spectrumBuffer = tempSpectrumBuffer;
    return tempSpectrumBuffer;
}

@end

#pragma mark - 使用 C 方法 减少计算耗时

NSArray *CCDASCreateFrequencyWeights(float frequency, int fftSize) {
    // 44100.0 / fftSize
    float Δf = frequency / (float)fftSize;
    int bins = fftSize / 2;
    
    float f[bins];
    for (int i = 0; i < bins; i++) {
        f[i] = (1.0 * i ) * Δf;
        f[i] = f[i] * f[i];
    }
    
    float c1 = powf(12194.217, 2.0);
    float c2 = powf(20.598997, 2.0);
    float c3 = powf(107.65265, 2.0);
    float c4 = powf(737.86223, 2.0);
    
    float num[bins];
    float den[bins];
    NSMutableArray *weightsArray = [NSMutableArray arrayWithCapacity:bins];
    for (int i = 0; i < bins; i++) {
        num[i] = c1 * f[i] * f[i];
        den[i] = (f[i] + c2) * sqrtf((f[i] + c3) * (f[i] + c4)) * (f[i] + c1);
        float weights = 1.2589 * num[i] / den[i];
        [weightsArray addObject: [NSNumber numberWithFloat:weights]];
    }
    return weightsArray.copy;
}

NSArray *CCDAudioSpectrumFFT(AVAudioPCMBuffer *buffer, FFTSetup fftSetup, int fftSize) {
    int fftSizeHalf = fftSize / 2;
    //1：抽取buffer中的样本数据
    float *const *floatChannelData = buffer.floatChannelData;
    float *const *channels = floatChannelData;
    
    AVAudioChannelCount channelCount = buffer.format.channelCount;
    BOOL isInterleaved = buffer.format.isInterleaved;
    NSMutableArray *amplitudes = [NSMutableArray array];
    if (isInterleaved) {
        // deinterleave
        float interleavedData[fftSize * channelCount];
        memcpy(interleavedData, floatChannelData[0], fftSize * channelCount);
        float *channelsTemp[channelCount];
        for (int i = 0; i < channelCount; i++) {
            int count = 0;
            for (int j = i; j < (fftSize * channelCount); j += channelCount) {
                count++;
            }
            float channelData[count];
            int idx = 0;
            for (int j = i; j < (fftSize * channelCount); j += channelCount) {
                channelData[idx] = interleavedData[j];
                idx++;
            }
            channelsTemp[i] = channelData;
        }
        channels = channelsTemp;
    }
    
    for (int i = 0; i < channelCount; i++) {
        float *channel = channels[i];
        //2: 加汉宁窗
        float window[fftSize];
        vDSP_hann_window(window, (vDSP_Length)(fftSize), vDSP_HANN_NORM);
        vDSP_vmul(channel, 1, window, 1, channel, 1, fftSize);
        
        //3: 将实数包装成FFT要求的复数fftInOut，既是输入也是输出
        float reap[fftSizeHalf];
        float imap[fftSizeHalf];
        DSPSplitComplex fftInOut = (DSPSplitComplex){reap, imap};
        vDSP_ctoz((DSPComplex *)channel, 2, &fftInOut, 1, (vDSP_Length)(fftSizeHalf));
        
        //4：执行FFT
        vDSP_fft_zrip(fftSetup, &fftInOut, 1, (vDSP_Length)(round(log2(fftSize))), FFT_FORWARD);
        
        //5：调整FFT结果，计算振幅
        fftInOut.imagp[0] = 0;
        float fftNormFactor = 1.0 / (float)(fftSize);
        
        vDSP_vsmul(fftInOut.realp, 1, &fftNormFactor, fftInOut.realp, 1, (vDSP_Length)(fftSizeHalf));
        vDSP_vsmul(fftInOut.imagp, 1, &fftNormFactor, fftInOut.imagp, 1, (vDSP_Length)(fftSizeHalf));
        
        float channelAmplitudes[fftSizeHalf];
        vDSP_zvabs(&fftInOut, 1, channelAmplitudes, 1, (vDSP_Length)(fftSizeHalf));
        //直流分量的振幅需要再除以2
        channelAmplitudes[0] = channelAmplitudes[0] / 2;
        
        int count = fftSizeHalf;
        NSMutableArray *arry = [NSMutableArray array];
        for (NSUInteger c = 0; c < count; c++) {
            float val = channelAmplitudes[c];
            [arry addObject: [NSNumber numberWithFloat:val]];
        }
        [amplitudes addObject:arry.copy];
    }
    return amplitudes.copy;
}

float CCDASFindMaxAmplitude(CCDAudioBandsInfo *band, NSArray *amplitudes, float bandWidth) {
    NSUInteger amplitudesCount = amplitudes.count;
    NSUInteger startIndex = (NSUInteger)(round(band.lowerFrequency / bandWidth));
    NSUInteger endIndex = MIN((NSUInteger)(round(band.upperFrequency / bandWidth)), amplitudesCount - 1);
    if (startIndex >= amplitudesCount || endIndex >= amplitudesCount) return 0;
    if ((endIndex - startIndex) == 0) {
        return [amplitudes[startIndex] floatValue];
    }
//    NSMutableArray *tmps = [NSMutableArray array];
//    for (NSUInteger i = startIndex; i <= endIndex; i++) {
//        [tmps addObject:[amplitudes[i] copy]];
//    }
//    NSNumber *max = [tmps valueForKeyPath:@"@max.self"];
//    return max.floatValue;
    //使用遍历替换
    float maxValue = 0;
    for (NSUInteger i = startIndex; i <= endIndex; i++) {
        maxValue = MAX(maxValue, [amplitudes[i] floatValue]);
    }
    return maxValue;
}

//使用加权平均, 消除锯齿过多，使波形更明显
NSMutableArray *CCDASHighlightWaveform(NSArray *spectrum) {
    //1: 定义权重数组，数组中间的5表示自己的权重
    //   可以随意修改，个数需要奇数
    int weightsCount = 7;
    float weights[] = {1, 2, 3, 5, 3, 2, 1};
    float totalWeights = 0;
    for (int i = 0; i < weightsCount; i++) {
        totalWeights += weights[i];
    }
    int startIndex = weightsCount / 2;
    //2: 开头几个不参与计算
    NSMutableArray *averagedSpectrum = [NSMutableArray array];
    
    NSUInteger spectrumCount = spectrum.count;
    for (NSUInteger i = 0; i < startIndex; i++) {
        [averagedSpectrum addObject:spectrum[i]];
    }
    
    for (int i = startIndex; i < (spectrumCount - startIndex); i++) {
        //3: zip作用: zip([a,b,c], [x,y,z]) -> [(a,x), (b,y), (c,z)]
        int count = MIN(((i + startIndex) - (i - startIndex) + 1), weightsCount);
        int zipOneIdx = (i - startIndex);
        float total = 0;
        for (int j = 0; j < count; j++) {
            total += [spectrum[zipOneIdx] floatValue] * weights[j];
            zipOneIdx++;
        }
        float averaged = total / totalWeights;
        [averagedSpectrum addObject: [NSNumber numberWithFloat:averaged]];
        
    }
    //4：末尾几个不参与计算
    NSUInteger idx = (spectrumCount - startIndex);
    for (NSUInteger i = idx; i < spectrumCount; i++) {
        [averagedSpectrum addObject:spectrum[i]];
    }
    return averagedSpectrum;
}
