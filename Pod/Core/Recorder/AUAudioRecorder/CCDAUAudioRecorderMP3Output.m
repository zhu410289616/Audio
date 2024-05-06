//
//  CCDAUAudioRecorderMP3Output.m
//  CicadaAudio
//
//  Created by 十年之前 on 2024/4/21.
//

#import "CCDAUAudioRecorderMP3Output.h"

@implementation CCDAUAudioRecorderMP3Output

- (instancetype)init
{
    self = [super init];
    if (self) {
        AudioStreamBasicDescription des;
        des.mSampleRate = 44100;
        des.mFormatID = kAudioFormatLinearPCM;
        des.mFormatFlags = kAudioFormatFlagIsSignedInteger;
        des.mFramesPerPacket = 1;
        des.mChannelsPerFrame = 1;
        des.mBitsPerChannel = 16;
        des.mBytesPerPacket = 2;
        des.mBytesPerFrame = 2;
        
        self.audioFormat = des;
    }
    return self;
}

#pragma mark - CCDAudioUnitRecorderOutput

- (void)receiveAudio:(AudioBufferList)bufferList
{
    UInt32 dataSize = bufferList.mBuffers[0].mDataByteSize;
    void *data = bufferList.mBuffers[0].mData;
    [self receiveAudio:data size:dataSize];
}

@end
