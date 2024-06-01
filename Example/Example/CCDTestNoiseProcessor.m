//
//  CCDTestNoiseProcessor.m
//  Example
//
//  Created by 十年之前 on 2024/5/18.
//

#import "CCDTestNoiseProcessor.h"

@interface CCDTestNoiseProcessor ()

@end

@implementation CCDTestNoiseProcessor

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
            [self write:(void *)pcmData.bytes maxSize:pcmData.length];
        } else {
            [self write:data maxSize:dataSize];
        }
    }
}

@end
