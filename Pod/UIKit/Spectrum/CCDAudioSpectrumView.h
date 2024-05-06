//
//  SpectrumView.h
//  AudioSpectrumDemo
//
//  Created by user on 2019/5/8.
//  Copyright © 2019 adu. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CCDAudioSpectraStyle) {
    CCDAudioSpectraStyleRect = 0, //直角
    CCDAudioSpectraStyleRound //圆角
};

FOUNDATION_EXPORT CGFloat CCDAudioTranslateAmplitudeToYPosition(CGFloat amplitude,
                                                                CGRect contarinerRect,
                                                                CGFloat topSpace,
                                                                CGFloat bottomSpace);

/// 一步一步教你实现iOS音频频谱动画
/// https://juejin.cn/post/6844903791670591495
@interface CCDAudioSpectrumView : UIView

@property (nonatomic, assign) CGFloat barWidth;
@property (nonatomic, assign) CGFloat space;
@property (nonatomic, assign) CGFloat bottomSpace;
@property (nonatomic, assign) CGFloat topSpace;

- (void)updateSpectra:(NSArray *)spectra withStype:(CCDAudioSpectraStyle)style;

@end

NS_ASSUME_NONNULL_END
