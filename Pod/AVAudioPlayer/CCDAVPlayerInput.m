//
//  CCDAVPlayerInput.m
//  AFNetworking
//
//  Created by ruhong zhu on 2020/9/5.
//

#import "CCDAVPlayerInput.h"

@implementation CCDAVPlayerInput

@synthesize audioPath;

- (NSURL *)fileURL
{
    NSURL *theURL = nil;
    if ([self.audioPath hasPrefix:@"http://"]
        || [self.audioPath hasPrefix:@"https://"]) {
        theURL = [NSURL URLWithString:self.audioPath];
    } else {
        theURL = [NSURL fileURLWithPath:self.audioPath];
    }
    return theURL;
}

@end
