//
//  CCDAudioRawEncoder.m
//  CCDAudio
//
//  Created by 十年之前 on 2024/6/1.
//

#import "CCDAudioRawEncoder.h"

@interface CCDAudioRawEncoder ()

@end

@implementation CCDAudioRawEncoder

@synthesize inASBD = _inASBD;
@synthesize outASBD = _outASBD;

- (void)cleanup
{}

- (void)setup
{}

- (void)encodeRawData:(NSData *)rawData completion:(void (^)(AudioBufferList *outAudioBufferList))completion
{}

@end
