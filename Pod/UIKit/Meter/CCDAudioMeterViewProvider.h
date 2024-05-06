//
//  CCDAudioMeterViewProvider.h
//  Cicada
//
//  Created by ruhong zhu on 2020/7/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CCDAudioMeterViewProvider <NSObject>

@property (nonatomic, assign) NSUInteger numOfLevels;
@property (nonatomic, assign) NSUInteger levelWidth;
@property (nonatomic, assign) NSUInteger levelMargin;

- (void)resetLevelData;
- (void)updateLevelMeter:(float)level;

@end

NS_ASSUME_NONNULL_END
