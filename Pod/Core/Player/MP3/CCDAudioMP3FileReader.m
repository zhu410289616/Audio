//
//  CCDAudioMP3FileReader.m
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/31.
//

#import "CCDAudioMP3FileReader.h"
#import "CCDAudioDefines.h"
#import <AudioToolbox/AudioToolbox.h>

@interface CCDAudioMP3FileReader ()

@property (nonatomic, strong) NSURL *audioURL;
@property (assign, nonatomic) AudioFileID audioFileID;

@end

@implementation CCDAudioMP3FileReader

- (void)dealloc
{
}

- (instancetype)initWithURL:(NSURL *)audioURL
{
    if (self = [super init]) {
        _audioURL = audioURL;
    }
    return self;
}

- (void)readConfig:(void (^)(NSInteger, NSInteger))completion
{
    if (self.audioURL.path == 0) {
        !completion ?: completion(0, 0);
        return;
    }
    
    OSStatus status = AudioFileOpenURL((__bridge CFURLRef)_audioURL,
                                       kAudioFileReadPermission,
                                       0,
                                       &_audioFileID);
    if (status != noErr) {
        CCDAudioLogE(@"AudioFileOpenURL: %@", @(status));
        return;
    }
    
    AudioStreamBasicDescription audioFormat;
    uint32_t size = sizeof(audioFormat);
    status = AudioFileGetProperty(_audioFileID, kAudioFilePropertyDataFormat, &size, &audioFormat);
    if (status != noErr) {
        CCDAudioLogE(@"AudioFileGetProperty: %@", @(status));
        return;
    }
    !completion ?: completion(audioFormat.mSampleRate, audioFormat.mChannelsPerFrame);
}

- (NSData *)readData
{
    
    
    return nil;
}

@end
