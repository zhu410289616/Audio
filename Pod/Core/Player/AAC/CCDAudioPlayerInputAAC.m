//
//  CCDAudioPlayerInputAAC.m
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/26.
//

#import "CCDAudioPlayerInputAAC.h"
#import "CCDAudioAACFileReader.h"
#import "CCDAudioAACDecoder.h"
#import "CCDAudioRawDecoder.h"
#import "CCDAudioUtil.h"

#import <libextobjc/EXTScope.h>

@interface CCDAudioPlayerInputAAC ()

@property (nonatomic, strong) NSMutableData *pcmDataBuffer;

@property (nonatomic, strong) NSURL *audioURL;
@property (nonatomic, strong) id<CCDAudioReaderProvider> reader;
/// 采样率；
@property (nonatomic, assign) NSInteger sampleRate;
/// 通道数；
@property (nonatomic, assign) NSInteger channels;
/// 缓存的多声道pcm数据；
@property (nonatomic, strong) NSMutableArray *pcmBuffers;
/// 缓存的pcm数据长度；
@property (nonatomic, assign) NSInteger currentBufferLength;

@property (nonatomic, strong) id<CCDAudioDecoderProvider> decoder;

@end

@implementation CCDAudioPlayerInputAAC

@synthesize audioPath = _audioPath;
@synthesize audioFormat = _audioFormat;

- (instancetype)initWithURL:(NSURL *)audioURL
{
    if (self = [super init]) {
        _pcmDataBuffer = [NSMutableData data];
        _audioURL = audioURL;
        _reader = [[CCDAudioAACFileReader alloc] initWithFilePath:audioURL.path];
        __block NSInteger theSampleRate = 44100;
        __block NSInteger theChannels = 1;
        [_reader readConfig:^(NSInteger sampleRate, NSInteger channels) {
            theSampleRate = sampleRate;
            theChannels = channels;
        }];
        _sampleRate = theSampleRate;
        _channels = theChannels;
        _pcmBuffers = @[].mutableCopy;
        for (NSInteger i=0; i<theChannels; i++) {
            [_pcmBuffers addObject:[NSMutableData data]];
        }
        _currentBufferLength = 0;
        _audioFormat = CCDAudioCreateASBD_PCM16(theSampleRate, theChannels);
    }
    return self;
}

#pragma mark - CCDAudioPlayerDataInput

- (void)begin
{
    [self.reader open];
    
    NSInteger theSampleRate = self.sampleRate;
    NSInteger theChannels = self.channels;
    
    self.decoder = [[CCDAudioRawDecoder alloc] init];
    self.decoder.inASBD = CCDAudioCreateASBD_AAC(theSampleRate, theChannels);
    self.decoder.outASBD = CCDAudioCreateASBD_PCM16(theSampleRate, theChannels);
    [self.decoder setup];
}

- (void)end
{
    [self.reader close];
    [self.decoder cleanup];
}

- (void)input:(CCDAudioBufferListCallback)callback bufferSize:(NSInteger)bufferSize
{
    if (self.currentBufferLength < bufferSize) {
        NSData *rawData = [self.reader readData];
        
        /// 回调 aac 数据，用于推流
        if (rawData.length > 0) {
            AudioBufferList *aac = CCDAudioBufferAlloc(self.channels, (void *)rawData.bytes, rawData.length);
            !self.aacCallback ?: self.aacCallback(aac, rawData.length);
        }
        
        @weakify(self);
        [self.decoder decodeRawData:rawData completion:^(AudioBufferList * _Nonnull outAudioBufferList) {
            @strongify(self);
            for (NSInteger i=0; i<outAudioBufferList->mNumberBuffers; i++) {
                NSMutableData *pcmBuffer = self.pcmBuffers[i];
                [pcmBuffer appendBytes:outAudioBufferList->mBuffers[i].mData length:outAudioBufferList->mBuffers[i].mDataByteSize];
            }
            self.currentBufferLength = [self.pcmBuffers[0] length];
        }];
    }
    
    NSArray *pcmBuffers = self.pcmBuffers;
    NSInteger readSize = 0;
    if (self.currentBufferLength > bufferSize) {
        readSize = bufferSize;
    } else {
        readSize = self.currentBufferLength;
    }
    self.currentBufferLength = self.currentBufferLength - readSize;
    if (readSize == 0) {
        !callback ?: callback(NULL, 0);
        return;
    }
    
    NSInteger channels = self.channels;
    AudioBufferList *audioBufferList = CCDAudioBufferAlloc(channels);
    
    NSRange readRange = NSMakeRange(0, readSize);
    for (UInt32 i=0; i<channels; i++) {
        NSMutableData *pcmBuffer = pcmBuffers[i];
        NSData *readData = [pcmBuffer subdataWithRange:readRange];
        
        uint8_t *buffer = (uint8_t *)malloc(readSize);
        memset(buffer, 0, readSize);
        memcpy(buffer, readData.bytes, readSize);
        
        audioBufferList->mBuffers[i].mNumberChannels = 1;
        audioBufferList->mBuffers[i].mData = buffer;
        audioBufferList->mBuffers[i].mDataByteSize = (UInt32)readSize;
        
        // remain
        NSRange remainRange = NSMakeRange(readSize, pcmBuffer.length - readSize);
        pcmBuffer.data = [pcmBuffer subdataWithRange:remainRange];
    }
    
    CCDAudioLogD(@"buffer remain length: %@, read size: %@", @([self.pcmBuffers[0] length]), @(readSize));
    !callback ?: callback(audioBufferList, readSize);
//    CCDAudioBufferRelease(audioBufferList);
}

- (void)read:(CCDAudioPlayerInCallback)callback maxSize:(NSInteger)maxSize
{
    if (self.pcmDataBuffer.length < maxSize) {
        NSData *rawData = [self.reader readData];
        if (rawData) {
            /// 方式一：通过block返回数据
            @weakify(self);
            [self.decoder decodeRawData:rawData completion:^(AudioBufferList * _Nonnull outAudioBufferList) {
                @strongify(self);
                [self.pcmDataBuffer appendBytes:outAudioBufferList->mBuffers[0].mData length:outAudioBufferList->mBuffers[0].mDataByteSize];
            }];
            
            /// 方式二：直接返回解码的PCM数据
//            AudioBufferList *pcm = [self.decoder decodeRawData:rawData];
//            if (pcm && pcm->mNumberBuffers > 0 && pcm->mBuffers[0].mData) {
//                [self.pcmDataBuffer appendBytes:pcm->mBuffers[0].mData length:pcm->mBuffers[0].mDataByteSize];
//                CCDAudioBufferRelease(pcm);
//            }
        }
    }
    
    void *buffer = NULL;
    NSInteger readSize = 0;
    
    if (self.pcmDataBuffer.length > maxSize) {
        NSRange readRange = NSMakeRange(0, maxSize);
        NSData *readData = [self.pcmDataBuffer subdataWithRange:readRange];
        buffer = (void *)readData.bytes;
        readSize = readData.length;
        // remain
        NSRange range = NSMakeRange(readSize, self.pcmDataBuffer.length - readSize);
        self.pcmDataBuffer.data = [self.pcmDataBuffer subdataWithRange:range];
    } else {
        NSRange readRange = NSMakeRange(0, self.pcmDataBuffer.length);
        NSData *readData = [self.pcmDataBuffer subdataWithRange:readRange];
        buffer = (void *)readData.bytes;
        readSize = readData.length;
        // remain
        self.pcmDataBuffer = [NSMutableData data];
    }
    
    CCDAudioLogD(@"pcm data buffer size: %@", @(self.pcmDataBuffer.length));
    !callback ?: callback(buffer, readSize);
}

@end
