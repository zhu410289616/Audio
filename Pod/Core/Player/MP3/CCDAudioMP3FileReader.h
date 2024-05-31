//
//  CCDAudioMP3FileReader.h
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/31.
//

#import <Foundation/Foundation.h>
#import "CCDAudioReaderProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface CCDAudioMP3FileReader : NSObject <CCDAudioReaderProvider>

- (instancetype)initWithURL:(NSURL *)audioURL;

@end

NS_ASSUME_NONNULL_END
