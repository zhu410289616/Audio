//
//  CCDAudioAACFileReader.h
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/26.
//

#import <Foundation/Foundation.h>
#import "CCDAudioReaderProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface CCDAudioAACFileReader : NSObject <CCDAudioReaderProvider>

- (instancetype)initWithFilePath:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
