//
//  CCDAudioDefines.h
//  Pods
//
//  Created by ruhong zhu on 2020/6/13.
//

#ifndef CCDAudioDefines_h
#define CCDAudioDefines_h

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

typedef NS_ENUM(NSInteger, CCDAudioType) {
    CCDAudioTypeM4A = 0,            //formatID: kAudioFormatMPEG4AAC
    CCDAudioTypeCaf,                //formatID: kAudioFormatLinearPCM
    CCDAudioTypeAMR,
    CCDAudioTypeMP3,
    CCDAudioTypeWav,
    CCDAudioTypeUnknown
};

typedef NS_ENUM(NSInteger, CCDAudioRecordStatus) {
    CCDAudioRecordStatusNone = 0,
    CCDAudioRecorderErrorCodeFile,              //文件操作错误
    CCDAudioRecorderErrorCodeQueue,             //音频队列错误
    CCDAudioRecorderErrorCodeSession,           //session错误
    CCDAudioRecorderErrorCodeUnknown            //未知错误
};

#pragma mark - struct

typedef struct CCDAudioFormat {
    CCDAudioType                audioType;
    AudioStreamBasicDescription asbd;
} CCDAudioFormat;

typedef CCDAudioFormat *CCDAudioFormatRef;

//typedef struct CCDAudioBufferInfo {
////    AudioBuffer     mAudioBuffer[1];
//    void *          mAudioData;
//    UInt32          mAudioDataByteSize;
//} CCDAudioBufferInfo;
//typedef CCDAudioBufferInfo *CCDAudioBufferInfoRef;

typedef struct CCDAudioQueueInputData {
    void                                *inUserData;
    AudioQueueRef                       inAQ;
    AudioQueueBufferRef                 inBuffer;
    const AudioTimeStamp                *inStartTime;
    UInt32                              inNumPackets;
    const AudioStreamPacketDescription  *inPacketDesc;
} CCDAudioQueueInputData;
typedef CCDAudioQueueInputData *CCDAudioQueueInputDataRef;

#pragma mark - log

#define CCDAdudioDebug

#ifdef CCDAdudioDebug
#define CCDAudioLog(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define CCDAudioLog(format, ...)
#endif

#define CCDAudioLogError(...) do { NSLog(__VA_ARGS__); }while(0)

#pragma mark - error

FOUNDATION_EXPORT NSString * const CCDAudioErrorDomain;
FOUNDATION_EXPORT NSError * CCDAudioMakeError(NSInteger code, NSString *msg);

#define CCDAudioCheckError(errorCode, errorDescription) do { \
CCDAudioLogError(@"CCDAudio: %@", errorDescription); \
if (error) { *error = [NSError errorWithDomain:CCDAudioErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: errorDescription}]; }}while(0)

@interface CCDAudioDefines : NSObject

@end

#endif /* CCDAudioDefines_h */
