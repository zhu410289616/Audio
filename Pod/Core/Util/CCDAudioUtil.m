//
//  CCDAudioUtil.m
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/12.
//

#import "CCDAudioUtil.h"

AudioStreamBasicDescription CCDAudioCreateASBD_PCM16(NSInteger sampleRate, NSInteger channels)
{
    UInt16 bytesPerSample = sizeof(SInt16);
    
    AudioStreamBasicDescription audioFormat = {0};
    audioFormat.mSampleRate = sampleRate;
    /// 1是单声道，2就是立体声；这里的数量决定了AudioBufferList的mBuffers长度是1还是2；
    audioFormat.mChannelsPerFrame = (UInt32)channels;
    audioFormat.mFormatID = kAudioFormatLinearPCM;
    /// 详细描述了音频数据的数字格式，整数还是浮点数，大端还是小端；
    /// 注意：双声道需要设置为kAudioFormatFlagIsNonInterleaved，否则初始化AudioUnit会出现错误 1718449215；
    /// kAudioFormatFlagIsNonInterleaved：
    /// 非交错模式，即首先记录的是一个周期内所有帧的左声道样本，再记录所有右声道样本；
    /// 交错模式，数据以连续帧的方式存放，即首先记录帧1的左声道样本和右声道样本，再开始帧2的记录；
    audioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsNonInterleaved;
    audioFormat.mFramesPerPacket = 1;
    /// 采样位数，数字越大，分辨率越高；16位可以记录65536个数，一般来说够用了；
    audioFormat.mBitsPerChannel = 8 * bytesPerSample;
    audioFormat.mBytesPerFrame = bytesPerSample;
    /// 下面就是设置声音采集时的一些值
    /// 比如：采样率为44.1kHZ，采样精度为16位的双声道；
    /// 可以算出比特率（bps）是44100*16*2bps，每秒的音频数据是固定的44100*16*2/8字节；
    /// 官方解释：满足下面这个公式时，上面的mFormatFlags会隐式设置为kAudioFormatFlagIsPacked
    /// ((mBitsPerSample / 8) * mChannelsPerFrame) == mBytesPerFrame
    audioFormat.mBytesPerPacket = bytesPerSample;
    return audioFormat;
}

AudioStreamBasicDescription CCDAudioCreateASBD_PCM32(NSInteger sampleRate, NSInteger channels)
{
    UInt32 bytesPerSample = sizeof(SInt32);
    
    AudioStreamBasicDescription audioFormat = {0};
    audioFormat.mSampleRate = sampleRate;
    /// 1是单声道，2就是立体声；这里的数量决定了AudioBufferList的mBuffers长度是1还是2；
    audioFormat.mChannelsPerFrame = (UInt32)channels;
    audioFormat.mFormatID = kAudioFormatLinearPCM;
    /// 详细描述了音频数据的数字格式，整数还是浮点数，大端还是小端；
    /// 注意：双声道需要设置为kAudioFormatFlagIsNonInterleaved，否则初始化AudioUnit会出现错误 1718449215；
    /// kAudioFormatFlagIsNonInterleaved：
    /// 非交错模式，即首先记录的是一个周期内所有帧的左声道样本，再记录所有右声道样本；
    /// 交错模式，数据以连续帧的方式存放，即首先记录帧1的左声道样本和右声道样本，再开始帧2的记录；
    audioFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved | kAudioFormatFlagIsPacked;
    audioFormat.mFramesPerPacket = 1;
    /// 采样位数，数字越大，分辨率越高；16位可以记录65536个数，一般来说够用了；
    audioFormat.mBitsPerChannel = 8 * bytesPerSample;
    audioFormat.mBytesPerFrame = bytesPerSample;
    /// 下面就是设置声音采集时的一些值
    /// 比如：采样率为44.1kHZ，采样精度为16位的双声道；
    /// 可以算出比特率（bps）是44100*16*2bps，每秒的音频数据是固定的44100*16*2/8字节；
    /// 官方解释：满足下面这个公式时，上面的mFormatFlags会隐式设置为kAudioFormatFlagIsPacked
    /// ((mBitsPerSample / 8) * mChannelsPerFrame) == mBytesPerFrame
    audioFormat.mBytesPerPacket = bytesPerSample;
    return audioFormat;
}

AudioStreamBasicDescription CCDAudioCreateASBD_AAC(NSInteger sampleRate, NSInteger channels)
{
    AudioStreamBasicDescription audioFormat = {0};
    audioFormat.mSampleRate = sampleRate;
    /// 1是单声道，2就是立体声；这里的数量决定了AudioBufferList的mBuffers长度是1还是2；
    audioFormat.mChannelsPerFrame = (UInt32)channels;
    audioFormat.mFormatID = kAudioFormatMPEG4AAC;
    audioFormat.mFormatFlags = kMPEG4Object_AAC_LC;
    /// AAC 固定是 1024，这个是由 AAC 编码规范规定的，对于未压缩数据设置为 1；
    audioFormat.mFramesPerPacket = 1024;
    /// 压缩格式设置为 0；
    audioFormat.mBitsPerChannel = 0;
    /// 压缩格式设置为 0；
    audioFormat.mBytesPerFrame = 0;
    /// 动态大小设置为 0；
    audioFormat.mBytesPerPacket = 0;
    return audioFormat;
}

AudioStreamBasicDescription CCDAudioCreateASBD_MP3(NSInteger sampleRate, NSInteger channels)
{
    AudioStreamBasicDescription audioFormat = {0};
    audioFormat.mSampleRate = sampleRate;
    audioFormat.mChannelsPerFrame = (UInt32)channels;
    audioFormat.mFormatID = kAudioFormatMPEGLayer3;
    audioFormat.mFramesPerPacket = 576; //采样个数，就是说一帧里面有多少个样本
    audioFormat.mBitsPerChannel = 0;
    audioFormat.mBytesPerFrame = 0;
    audioFormat.mBytesPerPacket = 0;
    return audioFormat;
}

AudioBufferList *__attribute__((overloadable)) CCDAudioBufferAlloc(NSInteger channels, NSInteger sizePerChannel)
{
    return CCDAudioBufferAlloc(channels, NULL, sizePerChannel);
}

AudioBufferList *__attribute__((overloadable)) CCDAudioBufferAlloc(NSInteger channels, void * _Nullable bytesPerChannel, NSInteger sizePerChannel)
{
    void *bytes = (void *)bytesPerChannel;
    NSInteger size = sizePerChannel;
    
    NSInteger inBufferListSize = sizeof(AudioBufferList) + (channels - 1) * sizeof(AudioBuffer);
    AudioBufferList *inAudioBufferList = malloc(inBufferListSize);
    memset(inAudioBufferList, 0, inBufferListSize);
    
    inAudioBufferList->mNumberBuffers = (UInt32)channels;
    for (UInt32 i=0; i<channels; i++) {
        uint8_t *buffer = (uint8_t *)malloc(size);
        memset(buffer, 0, size);
        if (NULL != bytes) {
            memcpy(buffer, bytes, size);
        }
        
        inAudioBufferList->mBuffers[i].mNumberChannels = 1;
        inAudioBufferList->mBuffers[i].mData = buffer;
        inAudioBufferList->mBuffers[i].mDataByteSize = (UInt32)size;
    }
    return inAudioBufferList;
}

void CCDAudioBufferReset(AudioBufferList *bufferList)
{
    if (NULL == bufferList) { return; }
    
    NSInteger number = bufferList->mNumberBuffers;
    for (NSInteger i=0; i<number; i++) {
        if (bufferList->mBuffers[i].mData) {
            memset(bufferList->mBuffers[i].mData, 0, bufferList->mBuffers[i].mDataByteSize);
        }
        bufferList->mBuffers[i].mDataByteSize = 0;
    }
}

void CCDAudioBufferRelease(AudioBufferList *bufferList)
{
    if (NULL == bufferList) { return; }
    
    NSInteger number = bufferList->mNumberBuffers;
    for (NSInteger i=0; i<number; i++) {
        if (NULL != bufferList->mBuffers[i].mData) {
            free(bufferList->mBuffers[i].mData);
            bufferList->mBuffers[i].mData = NULL;
        }
        bufferList->mBuffers[i].mDataByteSize = 0;
    }
    free(bufferList);
    bufferList = NULL;
}

@implementation CCDAudioUtil

@end
