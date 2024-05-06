//
//  CCDAudioDefines.m
//  Pods
//
//  Created by 十年之前 on 2023/8/1.
//

#import "CCDAudioDefines.h"

#pragma mark - error

NSString * const CCDAudioErrorDomain = @"CCDAudioErrorDomain";

NSError * CCDAudioMakeError(NSInteger code, NSString *msg)
{
    NSDictionary *userInfo = @{  NSLocalizedDescriptionKey: msg ?: @"Unknown" };
    return [NSError errorWithDomain:CCDAudioErrorDomain code:code userInfo:userInfo];
}

@implementation CCDAudioDefines

@end
