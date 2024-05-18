//
//  CCDWebRTCNoiseProcessor.m
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/18.
//

#import "CCDWebRTCNoiseProcessor.h"
#import "noise_suppression.h"
#import "CCDAudioDefines.h"

/// 计算10ms的音频需要的长度，采样率*0.01就是样本数量，
/// 然后乘以采样位数就是总位数，采样位数默认16位，再除以8就是字节数
inline static NSInteger CCDWebRTCNoiseLimitLength10ms(NSInteger rate)
{
    return rate * 0.01 * 16 / 8;
}

@interface CCDWebRTCNoiseProcessor ()

@property (nonatomic, assign) NsHandle *handle;
@property (nonatomic, assign) NSInteger sampleRate;
/// 处理的数据必须大于这个长度
@property (nonatomic, assign) NSInteger lengthLimit;

@end

@implementation CCDWebRTCNoiseProcessor

- (void)dealloc
{
    !_handle ?: WebRtcNs_Free(_handle);
}

- (instancetype)initWithSampleRate:(NSInteger)sampleRate mode:(int)mode
{
    if (self = [super init]) {
        _sampleRate = sampleRate;
        _lengthLimit = CCDWebRTCNoiseLimitLength10ms(sampleRate);
        _handle = WebRtcNs_Create();
        int status = WebRtcNs_Init(_handle, (uint32_t)sampleRate);
        if (status != 0) {
            CCDAudioLogE(@"WebRtcNs_Init: %@", @(status));
            return nil;
        }
        
        status = WebRtcNs_set_policy(_handle, mode);
        if (status != 0) {
            CCDAudioLogE(@"WebRtcNs_set_policy: %@", @(status));
            return nil;
        }
    }
    return self;
}

- (NSData *)nsProcess:(NSData *)pcmData
{
    NSInteger length = pcmData.length;
    if (length < self.lengthLimit) {
        return nil;
    }
    short *shortData = (short *)pcmData.bytes;
    //把10ms的音频样本数定义为s10，即sample10ms
    NSInteger s10 = MIN(320, self.sampleRate * 0.01);
    //总的样本数，除以s10，就是我们需要处理的次数
    NSInteger sTot = length / (s10 * 2);
    for(int i = 0; i < sTot; ++i) {
        short in_buffer[160] = {0};
        short out_buffer[160] = {0};
        memcpy(in_buffer, shortData, s10*2); //s10是样本数，乘以2是每个样本的字节数
        short *nsIn[1] = {in_buffer};
        short *nsOut[1] = {out_buffer};
        WebRtcNs_Analyze(_handle, nsIn[0]);
        WebRtcNs_Process(_handle, (const short *const *)nsIn, 1, nsOut);
        memcpy(shortData, out_buffer, s10*2);
        shortData += s10;
    }
    return pcmData;
}

@end
