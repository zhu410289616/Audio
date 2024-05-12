//
//  CCDAudioRecorderOutput.h
//  Cicada
//
//  Created by ruhong zhu on 2020/6/14.
//

#import <Foundation/Foundation.h>
#import "CCDAudioDefines.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CCDAudioRecorderOutput <NSObject>

@required

//@property (nonatomic, assign) CCDAudioType audioType;
@property (nonatomic, assign) AudioStreamBasicDescription audioFormat;
@property (nonatomic, strong) NSString *audioPath;

@optional

- (BOOL)openAudioFile;
- (void)closeAudioFile;

@end

@protocol CCDAudioRecorderDataOutput <CCDAudioRecorderOutput>

@property (nonatomic, assign) AudioStreamBasicDescription audioFormat;

- (void)begin;
- (void)end;

- (void)write:(AudioBufferList *)bufferList;
- (void)write:(void *)bytes maxSize:(NSInteger)maxSize;

@end

@protocol CCDAudioQueueRecorderOutput <CCDAudioRecorderOutput>

@required

- (void)receiveAudio:(const void *)aAudioData size:(UInt32)aSize;
- (void)copyEncoderCookieToFile:(AudioQueueRef)inAQ error:(NSError **)error;

@optional

- (void)didReceiveAudio:(CCDAudioQueueInputData)inData;
- (UInt32)computeRecordBufferSize:(const AudioStreamBasicDescription *)format;

@end

@protocol CCDAudioUnitRecorderOutput <CCDAudioRecorderOutput>

@required

- (void)receiveAudio:(AudioBufferList)bufferList;
- (void)receiveAudio:(const void *)aAudioData size:(UInt32)aSize;

@end

NS_ASSUME_NONNULL_END
