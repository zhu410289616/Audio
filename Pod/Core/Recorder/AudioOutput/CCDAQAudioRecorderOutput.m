//
//  CCDAQAudioRecorderOutput.m
//  Cicada
//
//  Created by ruhong zhu on 2020/6/14.
//

#import "CCDAQAudioRecorderOutput.h"

@interface CCDAQAudioRecorderOutput ()
{
    AudioFileID _audioFile;
    SInt64 _audioPacket;
}

@end

@implementation CCDAQAudioRecorderOutput

#pragma mark - CCDAudioRecorderOutput

- (void)begin
{
    NSString *filePath = self.audioPath;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        [fileManager removeItemAtPath:filePath error:nil];
    }
    
    AudioStreamBasicDescription audioFormat = self.audioFormat;
    _audioPacket = 0;
    
    CFURLRef url = CFURLCreateWithString(kCFAllocatorDefault, (CFStringRef)filePath, NULL);
    OSStatus status = AudioFileCreateWithURL(url, kAudioFileCAFType, &audioFormat, kAudioFileFlags_EraseFile, &_audioFile);
    if (status != noErr) {
        CCDAudioLogE(@"AudioFileCreateWithURL: %@", @(status));
    }
    !url ?: CFRelease(url);
}

- (void)end
{
    if (_audioFile) {
        AudioFileClose(_audioFile);
        _audioFile = NULL;
    }
}

- (void)write:(nonnull AudioBufferList *)bufferList
{    
}

#pragma mark - CCDAudioQueueRecorderOutput

- (void)didReceiveAudio:(CCDAudioQueueInputData)inData
{
    AudioQueueBufferRef inBuffer = inData.inBuffer;
    const AudioStreamPacketDescription *inPacketDesc = inData.inPacketDesc;
    UInt32 inNumPackets = inData.inNumPackets;
    
    OSStatus status = AudioFileWritePackets(_audioFile, FALSE, inBuffer->mAudioDataByteSize, inPacketDesc, _audioPacket, &inNumPackets, inBuffer->mAudioData);
    if (status != noErr) {
        CCDAudioLogE(@"AudioFileWritePackets error");
    }
    _audioPacket += inNumPackets;
}

- (void)copyEncoderCookieToFile:(AudioQueueRef)inAQ error:(NSError **)error
{
    UInt32 propertySize;
    // get the magic cookie, if any, from the converter
    OSStatus status = AudioQueueGetPropertySize(inAQ, kAudioQueueProperty_MagicCookie, &propertySize);
    
    // we can get a noErr result and also a propertySize == 0
    // -- if the file format does support magic cookies, but this file doesn't have one.
    if (status != noErr || propertySize == 0) {
        return;
    }
    
    Byte magicCookie[propertySize];
    UInt32 magicCookieSize;
    status = AudioQueueGetProperty(inAQ, kAudioQueueProperty_MagicCookie, magicCookie, &propertySize);
    if (status != noErr) {
        CCDAudioCheckError(status, @"Get audio converter's magic cookie failed");
        return;
    }
    magicCookieSize = propertySize;    // the converter lies and tell us the wrong size
    
    // now set the magic cookie on the output file
    UInt32 willEatTheCookie = false;
    // the converter wants to give us one; will the file take it?
    status = AudioFileGetPropertyInfo(_audioFile, kAudioFilePropertyMagicCookieData, NULL, &willEatTheCookie);
    if (status != noErr) {
        CCDAudioCheckError(status, @"Get property info error: willEatTheCookie");
        return;
    }
    
    if (willEatTheCookie) {
        status = AudioFileSetProperty(_audioFile, kAudioFilePropertyMagicCookieData, magicCookieSize, magicCookie);
        if (status != noErr) {
            CCDAudioCheckError(status, @"Set audio file's magic cookie error");
        }
    }
}

@end
