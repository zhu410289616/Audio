//
//  CCDRecorderView.h
//  Cicada
//
//  Created by ruhong zhu on 2020/8/2.
//

#import <UIKit/UIKit.h>
#import <CCDAudio/CCDAudioRecordMeterView.h>
#import <CCDAudio/CCDAudioSpectrumView.h>
#import <SCSiriWaveformView/SCSiriWaveformView.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCDRecorderView : UIView

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *stateLabel;

@property (nonatomic, strong) CCDAudioSpectrumView *spectrumView;
@property (nonatomic, strong) CCDAudioRecordMeterView *meterView;
@property (nonatomic, strong) SCSiriWaveformView *waveView;

- (void)updateStateInfo:(NSString *)info;

@end

NS_ASSUME_NONNULL_END
