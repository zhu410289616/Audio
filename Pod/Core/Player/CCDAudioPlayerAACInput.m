//
//  CCDAudioPlayerAACInput.m
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/26.
//

#import "CCDAudioPlayerAACInput.h"
#import "CCDAudioAACFileReader.h"
#import "CCDAudioAACDecoder.h"
#import "CCDAudioRawDecoder.h"
#import "CCDAudioUtil.h"

#import "QHDecodeByAudioConverter.h"
#import "CCDAudioRecorderOutputPCM.h"

#import <libextobjc/EXTScope.h>

@interface CCDAudioPlayerAACInput ()

@property (nonatomic, strong) NSMutableData *pcmDataBuffer;

@property (nonatomic, strong) NSURL *audioURL;
@property (nonatomic, strong) CCDAudioAACFileReader *aacReader;
@property (nonatomic, strong) id<CCDAudioDecoderProvider> aacDecoder;

/// 测试输出 pcm 数据
@property (nonatomic, strong) CCDAudioRecorderOutputPCM *outputTest;

@end

@implementation CCDAudioPlayerAACInput

@synthesize audioPath = _audioPath;
@synthesize audioFormat = _audioFormat;

- (instancetype)initWithURL:(NSURL *)audioURL
{
    if (self = [super init]) {
        _pcmDataBuffer = [NSMutableData data];
        _audioURL = audioURL;
        _aacReader = [[CCDAudioAACFileReader alloc] initWithFilePath:audioURL.path];
        __block NSInteger theSampleRate = 44100;
        __block NSInteger theChannels = 1;
        [_aacReader readConfig:^(NSInteger sampleRate, NSInteger channels) {
            theSampleRate = sampleRate;
            theChannels = channels;
        }];
        _audioFormat = CCDAudioCreateASBD_PCM32(theSampleRate, theChannels);
        
        _outputTest = [[CCDAudioRecorderOutputPCM alloc] init];
    }
    return self;
}

#pragma mark - CCDAudioPlayerDataInput

- (void)begin
{
    [self.outputTest begin];
    
    NSInteger theSampleRate = self.audioFormat.mSampleRate;
    NSInteger theChannels = self.audioFormat.mChannelsPerFrame;
    
    self.aacDecoder = [[CCDAudioAACDecoder alloc] init];
    self.aacDecoder = [[CCDAudioRawDecoder alloc] init];
//    self.aacDecoder = [[QHDecodeByAudioConverter alloc] init];
    self.aacDecoder.inASBD = CCDAudioCreateASBD_AAC(theSampleRate, theChannels);
    self.aacDecoder.outASBD = CCDAudioCreateASBD_PCM32(theSampleRate, theChannels);
    [self.aacDecoder setup];
}

- (void)end
{
    [self.outputTest end];
    [self.aacDecoder cleanup];
}

- (void)read:(CCDAudioPlayerInCallback)callback maxSize:(NSInteger)maxSize
{
    if (self.pcmDataBuffer.length < maxSize) {
        NSData *rawData = [self.aacReader readData];
        if (rawData) {
            @weakify(self);
            [self.aacDecoder decodeRawData:rawData completion:^(AudioBufferList * _Nonnull outAudioBufferList) {
                @strongify(self);
//                [self.outputTest write:outAudioBufferList];
                [self.pcmDataBuffer appendBytes:outAudioBufferList->mBuffers[0].mData length:outAudioBufferList->mBuffers[0].mDataByteSize];
            }];
            
//            AudioBufferList *pcm = [self.aacDecoder decodeRawData:rawData];
//            if (pcm && pcm->mNumberBuffers > 0 && pcm->mBuffers[0].mData) {
//                [self.outputTest write:pcm];
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
        self.pcmDataBuffer = [self.pcmDataBuffer subdataWithRange:range].mutableCopy;
    } else {
        NSRange readRange = NSMakeRange(0, self.pcmDataBuffer.length);
        NSData *readData = [self.pcmDataBuffer subdataWithRange:readRange];
        buffer = (void *)readData.bytes;
        readSize = readData.length;
        // remain
        self.pcmDataBuffer = [NSMutableData data];
    }
    !callback ?: callback(buffer, readSize);
}

@end
