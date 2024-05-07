//
//  CCDRecorderView.h
//  Cicada
//
//  Created by ruhong zhu on 2020/8/2.
//

#import <UIKit/UIKit.h>
#import "CCDAudioRecordMeterView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CCDRecorderView : UIView

@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) UIButton *soundTouchButton;
@property (nonatomic, strong) UIButton *recordButton;
@property (nonatomic, strong) UIButton *mp3RecordButton;
@property (nonatomic, strong) UIButton *auRecordButton;
@property (nonatomic, strong) CCDAudioRecordMeterView *meterView;

@end

NS_ASSUME_NONNULL_END
