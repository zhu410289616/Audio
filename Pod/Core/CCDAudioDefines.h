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

#ifdef DEBUG
#define CCDAudioLog(frmt, ...) do { NSLog(frmt, ## __VA_ARGS__); } while(0)
#else
#define CCDAudioLog(frmt, ...)
#endif

#if __has_include(<CCDBucket/CCDLogger.h>)
#import <CCDBucket/CCDLogger.h>
#define CCDAudioLogD(frmt, ...) do { DDLogDebug(frmt, ## __VA_ARGS__); } while(0)
#define CCDAudioLogE(frmt, ...) do { DDLogError(frmt, ## __VA_ARGS__); } while(0)
#define CCDAudioLogI(frmt, ...) do { DDLogInfo(frmt, ## __VA_ARGS__); } while(0)
#define CCDAudioLogV(frmt, ...) do { DDLogVerbose(frmt, ## __VA_ARGS__); } while(0)
#define CCDAudioLogW(frmt, ...) do { DDLogWarn(frmt, ## __VA_ARGS__); } while(0)
#else
#define CCDAudioLogD(frmt, ...) do { CCDAudioLog(frmt, ## __VA_ARGS__); } while(0)
#define CCDAudioLogE(frmt, ...) do { CCDAudioLog(frmt, ## __VA_ARGS__); } while(0)
#define CCDAudioLogI(frmt, ...) do { CCDAudioLog(frmt, ## __VA_ARGS__); } while(0)
#define CCDAudioLogV(frmt, ...) do { CCDAudioLog(frmt, ## __VA_ARGS__); } while(0)
#define CCDAudioLogW(frmt, ...) do { CCDAudioLog(frmt, ## __VA_ARGS__); } while(0)
#endif

#pragma mark - error

FOUNDATION_EXPORT NSString * const CCDAudioErrorDomain;
FOUNDATION_EXPORT NSError * CCDAudioMakeError(NSInteger code, NSString *msg);

#define CCDAudioCheckError(errorCode, errorDescription) \
do { \
CCDAudioLogE(@"CCDAudio: %@", errorDescription); \
if (error) { *error = [NSError errorWithDomain:CCDAudioErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: errorDescription}]; \
} \
} while(0)

@interface CCDAudioDefines : NSObject

@end

#endif /* CCDAudioDefines_h */
