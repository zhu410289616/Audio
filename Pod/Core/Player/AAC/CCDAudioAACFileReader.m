//
//  CCDAudioAACFileReader.m
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/26.
//

#import "CCDAudioAACFileReader.h"

@interface CCDAudioAACFileReader ()

@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, assign) FILE *file;

@end

@implementation CCDAudioAACFileReader

- (void)dealloc
{
    [self close];
}

- (instancetype)initWithFilePath:(NSString *)filePath
{
    if (self = [super init]) {
        _filePath = filePath;
    }
    return self;
}

- (void)readConfig:(void (^)(NSInteger, NSInteger))completion
{
    if (self.filePath.length == 0) {
        !completion ?: completion(0, 0);
        return;
    }
    
    const char *filename = [self.filePath UTF8String];
    FILE *file = fopen(filename, "rb+");
    int head_buf_size = 7;
    int *head_buf = malloc(head_buf_size);
    fread(head_buf, 1, head_buf_size, file);
    
    int freqIdx = ((int)(*(((uint8_t *)head_buf) + 2))&0x3C) >> 2;
    int c1 = ((int)(*(((uint8_t *)head_buf) + 2))&0x1) << 2;
    int c2 = ((int)(*(((uint8_t *)head_buf) + 3))&0xC0) >> 6;
    int chanCfg = c1 + c2;
    
    completion(freqIdx == 3 ? 48000 : 44100, chanCfg);
    
    free(head_buf); head_buf = NULL;
    fclose(file); file = NULL;
}

- (void)open
{
    const char *filename = [self.filePath UTF8String];
    _file = fopen(filename, "rb+");
}

- (void)close
{
    if (_file) {
        fclose(_file);
        _file = NULL;
    }
}

- (NSData *)readData
{
    if (feof(_file)) {
        return nil;
    }
    
    int head_buf_size = 7;
    int *head_buf = malloc(head_buf_size);
    fread(head_buf, 1, head_buf_size, _file);
    
    int s1 = ((int)(*(((uint8_t *)head_buf) + 3))&0x3) << 11;
    int s2 = ((int)(*(((uint8_t *)head_buf) + 4))) << 3;
    int s3 = (int)(*(((uint8_t *)head_buf) + 5)) >> 5;
    int size = s1 + s2 + s3;
    
    int raw_buf_size = size - head_buf_size;
    int *raw_buf = malloc(raw_buf_size);
    size_t read_size = fread(raw_buf, 1, raw_buf_size, _file);
    NSData *aacData = [[NSData alloc] initWithBytes:raw_buf length:read_size];
    
    free(head_buf); head_buf = NULL;
    free(raw_buf); raw_buf = NULL;
    
    return aacData;
}

@end
