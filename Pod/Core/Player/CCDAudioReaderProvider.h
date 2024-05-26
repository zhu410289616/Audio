//
//  CCDAudioReaderProvider.h
//  CCDAudio
//
//  Created by 十年之前 on 2024/5/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CCDAudioReaderProvider <NSObject>

- (void)readConfig:(void(^)(NSInteger sampleRate, NSInteger channels))completion;
- (NSData *)readData;

@end

NS_ASSUME_NONNULL_END
