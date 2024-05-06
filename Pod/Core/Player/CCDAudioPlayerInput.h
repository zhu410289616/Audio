//
//  CCDAudioPlayerInput.h
//  Cicada
//
//  Created by ruhong zhu on 2020/6/19.
//

#import <Foundation/Foundation.h>
#import "CCDAudioDefines.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CCDAudioPlayerInput <NSObject>

@required

@property (nonatomic, strong) NSString *audioId;
@property (nonatomic, strong) NSString *filePath;

@optional

@property (nonatomic, strong) NSURL *fileURL;

@end

NS_ASSUME_NONNULL_END
