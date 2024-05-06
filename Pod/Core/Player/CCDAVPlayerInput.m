//
//  CCDAVPlayerInput.m
//  AFNetworking
//
//  Created by ruhong zhu on 2020/9/5.
//

#import "CCDAVPlayerInput.h"

@implementation CCDAVPlayerInput

@synthesize audioId;
@synthesize filePath;
@synthesize fileURL = _fileURL;

- (NSURL *)fileURL
{
    if (_fileURL) {
        return _fileURL;
    }
    
    if ([self.filePath hasPrefix:@"http://"]
        || [self.filePath hasPrefix:@"https://"]) {
        _fileURL = [NSURL URLWithString:self.filePath];
    } else {
        _fileURL = [NSURL fileURLWithPath:self.filePath];
    }
    return _fileURL;
}

@end
