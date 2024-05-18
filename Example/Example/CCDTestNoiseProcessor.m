//
//  CCDTestNoiseProcessor.m
//  Example
//
//  Created by 十年之前 on 2024/5/18.
//

#import "CCDTestNoiseProcessor.h"
#import <CCDAudio/CCDWebRTCNoiseProcessor.h>

@interface CCDTestNoiseProcessor ()

@property (nonatomic, strong) CCDWebRTCNoiseProcessor *processor;

@end

@implementation CCDTestNoiseProcessor

- (instancetype)initWithSampleRate:(NSInteger)sampleRate
{
    self = [super initWithSampleRate:sampleRate];
    if (self) {
        _processor = [[CCDWebRTCNoiseProcessor alloc] initWithSampleRate:sampleRate mode:2];
    }
    return self;
}

- (void)write:(AudioBufferList *)bufferList
{
    NSInteger channels = bufferList->mNumberBuffers;
    for (NSInteger i=0; i<channels; i++) {
        UInt32 dataSize = bufferList->mBuffers[i].mDataByteSize;
        void *data = bufferList->mBuffers[i].mData;
        // 降噪处理
        NSData *pcmData = [NSData dataWithBytes:data length:dataSize];
        pcmData = [self.processor nsProcess:pcmData];
        if (pcmData) {
            [self write:pcmData.bytes maxSize:pcmData.length];
        } else {
            [self write:data maxSize:dataSize];
        }
    }
}

@end
