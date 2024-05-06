//
//  CCDAudioRecordMeterView.m
//  Cicada
//
//  Created by ruhong zhu on 2020/7/5.
//

#import "CCDAudioRecordMeterView.h"

@interface CCDAudioRecordMeterView ()

@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) CAShapeLayer *levelLayer;

@property (nonatomic, strong) NSMutableArray *currentLevels;
//@property (nonatomic, strong) UIBezierPath *levelPath;

@end

@implementation CCDAudioRecordMeterView

@synthesize numOfLevels = _numOfLevels;
@synthesize levelWidth = _levelWidth;
@synthesize levelMargin = _levelMargin;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _numOfLevels = 13;
        _levelWidth = 2.0f;
        _levelMargin = 4.0f;
        
        [self.layer addSublayer:self.gradientLayer];
        self.layer.mask = self.levelLayer;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.gradientLayer.bounds = self.bounds;
    self.levelLayer.bounds = self.bounds;
}

#pragma mark - getter & setter

- (CAGradientLayer *)gradientLayer
{
    if (nil == _gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.frame = self.bounds;
        _gradientLayer.colors = @[
            (__bridge id)[UIColor blueColor].CGColor,
            (__bridge id)[UIColor greenColor].CGColor
        ];
        _gradientLayer.startPoint = CGPointMake(0, 0);
        _gradientLayer.endPoint = CGPointMake(1, 0);
        _gradientLayer.type = kCAGradientLayerAxial;
    }
    return _gradientLayer;
}

- (CAShapeLayer *)levelLayer
{
    if (nil == _levelLayer) {
        _levelLayer = [CAShapeLayer layer];
        _levelLayer.frame = self.bounds;
        _levelLayer.strokeColor = [UIColor whiteColor].CGColor;
        _levelLayer.lineCap = kCALineCapRound;
    }
    return _levelLayer;
}

- (NSMutableArray *)currentLevels
{
    if (nil == _currentLevels) {
        NSArray *defaultLevels = @[
            @0.05, @0.05, @0.05, @0.05, @0.05,
            @0.05, @0.05, @0.05, @0.05, @0.05,
            @0.05, @0.05, @0.05, @0.05, @0.05,
        ];
        _currentLevels = [NSMutableArray arrayWithArray:defaultLevels];
    }
    return _currentLevels;
}

- (void)resetLevelData
{
    for (NSInteger i=0; i<self.currentLevels.count; i++) {
        self.currentLevels[i] = @0.05;
    }
    [self updateLevelLayer];
}

- (void)updateLevelMeter:(float)level
{
    if (self.currentLevels.count >= self.numOfLevels) {
        [self.currentLevels removeLastObject];
    }
    [self.currentLevels insertObject:@(level) atIndex:0];
    [self updateLevelLayer];
}

#pragma mark - private

- (void)updateLevelLayer
{
    if (self.currentLevels.count == 0) {
        return;
    }
    
    UIBezierPath *levelPath = [UIBezierPath bezierPath];
    CGFloat width = CGRectGetWidth(self.levelLayer.frame);
    CGFloat height = CGRectGetHeight(self.levelLayer.frame);
    CGFloat totalMargin = (self.currentLevels.count - 1) * self.levelMargin;
    CGFloat totalWidth = self.currentLevels.count * self.levelWidth;
    CGFloat startX = (width - totalWidth - totalMargin) / 2.0f;
    
    for (NSInteger i=0; i<self.currentLevels.count; i++) {
        CGFloat x = startX + i * (self.levelWidth + self.levelMargin);
        CGFloat pathH = [self.currentLevels[i] floatValue] * height;
        CGFloat startY = height / 2.0 - pathH / 2.0f;
        CGFloat endY = height / 2.0 + pathH / 2.0f;
        [levelPath moveToPoint:CGPointMake(x, startY)];
        [levelPath addLineToPoint:CGPointMake(x, endY)];
    }
    
    self.levelLayer.lineWidth = self.levelWidth;
    self.levelLayer.path = levelPath.CGPath;
}

@end
