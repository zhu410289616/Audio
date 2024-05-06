//
//  CCDAQAudioRecorderSTOutput.h
//  Pods
//
//  Created by ruhong zhu on 2021/7/3.
//

#import <Foundation/Foundation.h>
#import "CCDAudioRecorderOutput.h"

/// wav头部结构体
typedef struct CCDAudioWaveHeader {
    //内容为"RIFF"
    char riff[4];
    //存储文件的字节数（不包含ChunkID和ChunkSize这8个字节）
    int fileLength;
    //内容为"WAVE“
    char wavTag[4];
    //内容为"fmt"
    char fmt[4];
    //存储该子块的字节数（不含前面的Subchunk1ID和Subchunk1Size这8个字节）
    int size;
    //存储音频文件的编码格式，例如若为PCM则其存储值为1
    unsigned short formatTag;
    //声道数，单声道(Mono)值为1，双声道(Stereo)值为2，等等
    unsigned short channel;
    //采样率，如8k，44.1k等
    int sampleRate;
    //每秒存储的bit数，其值 = SampleRate * NumChannels * BitsPerSample / 8
    int bytePerSec;
    //块对齐大小，其值 = NumChannels * BitsPerSample / 8
    unsigned short blockAlign;
    //每个采样点的bit数，一般为8,16,32等
    unsigned short bitPerSample;
    //内容为“data”
    char data[4];
    //正式的数据部分的字节数，其值 = NumSamples * NumChannels * BitsPerSample / 8
    int dataSize;
} CCDAudioWaveHeader;

typedef CCDAudioWaveHeader *CCDAudioWaveHeaderRef;

void *CCDCreateWaveHeader(int fileLength,
                          short channel,
                          int sampleRate,
                          short bitPerSample);

/** 使用 sound touch 库 对录音做处理 */
@interface CCDAQAudioRecorderSTOutput : NSObject <CCDAudioQueueRecorderOutput>

/// 速度 <变速不变调>，取值范围：-50 ～ 100
@property (nonatomic, assign) double tempo;
/// 设置声音的pitch，取值范围：-12 ～ 12； (集音高变化semi-tones相比原来的音调) ；男: -8 女:8
@property (nonatomic, assign) double pitchSemiTones;
/// 设置声音的速率，取值范围：-50 ～ 100
@property (nonatomic, assign) double rateChange;

@end
