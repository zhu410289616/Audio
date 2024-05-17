//
//  CCDAudioRecorderOutputMP3.m
//  CCDAudio
//
//  Created by zhuruhong on 2024/5/17.
//

#import "CCDAudioRecorderOutputMP3.h"
#import "lame.h"

@interface CCDAudioRecorderOutputMP3 ()
{
    lame_t _lame;
}

@property (nonatomic, assign) NSInteger sampleRate;

@end

@implementation CCDAudioRecorderOutputMP3

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSString *name = [NSString stringWithFormat:@"audio_output.mp3"];
        self.audioPath = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
    }
    return self;
}

- (void)setupAudioFormat:(NSInteger)sampleRate
{
    [super setupAudioFormat:sampleRate];
    self.sampleRate = sampleRate;
}

- (void)begin
{
    [super begin];
    //mp3压缩参数
    _lame = lame_init();
    lame_set_num_channels(_lame, 1);
    lame_set_in_samplerate(_lame, (int)self.sampleRate);
    lame_set_out_samplerate(_lame, (int)self.sampleRate);
    lame_set_brate(_lame, 128);
    lame_set_mode(_lame, JOINT_STEREO);
    lame_set_quality(_lame, 2);
    lame_init_params(_lame);
}

- (void)end
{
    [super end];
    if (_lame) {
        lame_close(_lame);
        _lame = NULL;
    }
}

- (void)write:(AudioBufferList *)bufferList
{
    UInt32 dataSize = bufferList->mBuffers[0].mDataByteSize;
    void *data = bufferList->mBuffers[0].mData;
    
    short *pcmData = (short *)data;
    UInt32 pcmLen = dataSize;
    if (pcmLen < 2) { return; }
    
    int nsamples = pcmLen / 2;
    unsigned char buffer[pcmLen];
    //mp3 encode
    int recvLen = lame_encode_buffer(_lame, pcmData, pcmData, nsamples, buffer, pcmLen);
    if (recvLen <= 0) { return; }
    [self write:buffer maxSize:recvLen];
}

@end
