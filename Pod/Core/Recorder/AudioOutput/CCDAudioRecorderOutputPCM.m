//
//  CCDAudioRecorderOutputPCM.m
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/12.
//

#import "CCDAudioRecorderOutputPCM.h"

@interface CCDAudioRecorderOutputPCM ()

@property (nonatomic, strong) NSOutputStream *outputStream;

@end

@implementation CCDAudioRecorderOutputPCM

@synthesize audioPath = _audioPath;
@synthesize audioFormat = _audioFormat;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _audioPath = [NSTemporaryDirectory() stringByAppendingString:@"record.pcm"];
    }
    return self;
}

#pragma mark - getter & setter

- (NSOutputStream *)outputStream
{
    if (nil == _outputStream) {
        _outputStream = [[NSOutputStream alloc] initToFileAtPath:_audioPath append:NO];
    }
    return _outputStream;
}

#pragma mark - CCDAudioRecorderDataOutput

- (void)begin
{
    [self.outputStream open];
}

- (void)end
{
    [self.outputStream close];
}

- (void)write:(AudioBufferList *)bufferList
{
    !self.pcmCallback ?: self.pcmCallback(bufferList, bufferList->mBuffers[0].mDataByteSize);
    
    NSInteger channels = bufferList->mNumberBuffers;
    for (NSInteger i=0; i<channels; i++) {
        UInt32 dataSize = bufferList->mBuffers[i].mDataByteSize;
        void *data = bufferList->mBuffers[i].mData;
        [self write:data maxSize:dataSize];
    }
}

- (void)write:(void *)bytes maxSize:(NSInteger)maxSize
{
#ifdef DEBUG1
    CCDAudioLogD(@"write size: %@", @(maxSize));
    NSData *bufferData = [NSData dataWithBytes:bytes length:maxSize];
    CCDAudioLogD(@"buffer data: %@", bufferData);
#endif
    
    [self.outputStream write:bytes maxLength:maxSize];
}

@end
