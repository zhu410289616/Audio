//
//  CCDAudioPlayerInputPCM.m
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/12.
//

#import "CCDAudioPlayerInputPCM.h"
#import "CCDAudioUtil.h"

@interface CCDAudioPlayerInputPCM ()

@property (nonatomic, strong) NSInputStream *inputStream;

@end

@implementation CCDAudioPlayerInputPCM

@synthesize audioPath = _audioPath;
@synthesize audioFormat = _audioFormat;

- (instancetype)initWithURL:(NSURL *)audioURL
{
    if (self = [super init]) {
        _inputStream = [[NSInputStream alloc] initWithURL:audioURL];
    }
    return self;
}

#pragma mark - getter & setter

- (NSInputStream *)inputStream
{
    if (nil == _inputStream) {
        _inputStream = [[NSInputStream alloc] initWithFileAtPath:self.audioPath];
    }
    return _inputStream;
}

#pragma mark - CCDAudioPlayerDataInput

- (void)begin
{
    [self.inputStream open];
}

- (void)end
{
    [self.inputStream close];
}

- (void)input:(CCDAudioBufferListCallback)callback bufferSize:(NSInteger)bufferSize
{
    void *readBuffer = malloc(bufferSize);
    NSInteger readSize = [self.inputStream read:readBuffer maxLength:bufferSize];
    if (readSize <= 0) {
        !callback ?: callback(NULL, 0);
        !readBuffer ?: free(readBuffer);
        return;
    }
    
    NSInteger channels = self.audioFormat.mChannelsPerFrame;
    AudioBufferList *audioBufferList = CCDAudioBufferAlloc(channels);
    
    for (UInt32 i=0; i<channels; i++) {
        uint8_t *buffer = (uint8_t *)malloc(readSize);
        memset(buffer, 0, readSize);
        memcpy(buffer, readBuffer, readSize);
        
        audioBufferList->mBuffers[i].mNumberChannels = 1;
        audioBufferList->mBuffers[i].mData = buffer;
        audioBufferList->mBuffers[i].mDataByteSize = (UInt32)readSize;
    }
    
    !callback ?: callback(audioBufferList, readSize);
    !readBuffer ?: free(readBuffer);
}

@end
