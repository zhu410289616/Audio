//
//  CCDRecorderView.m
//  Cicada
//
//  Created by ruhong zhu on 2020/8/2.
//

#import "CCDRecorderView.h"

@implementation CCDRecorderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor lightGrayColor];
        
        _tableView = [[UITableView alloc] init];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.tableFooterView = [[UIView alloc] init];
        [self addSubview:_tableView];
        
        _stateLabel = [[UILabel alloc] init];
        _stateLabel.textColor = [UIColor whiteColor];
        _stateLabel.text = @"info";
        _stateLabel.numberOfLines = 0;
        _stateLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:_stateLabel];
        
        CGRect frame0 = CGRectMake(0, 0, frame.size.width, 100);
        _spectrumView = [[CCDAudioSpectrumView alloc] initWithFrame:frame0];
        _spectrumView.backgroundColor = [UIColor clearColor];
        [self addSubview:_spectrumView];
        
        _meterView = [[CCDAudioRecordMeterView alloc] initWithFrame:CGRectZero];
        [self addSubview:_meterView];
        
        _waveView = [[SCSiriWaveformView alloc] init];
        _waveView.backgroundColor = [UIColor clearColor];
        _waveView.waveColor = [UIColor whiteColor];
        _waveView.primaryWaveLineWidth = 3.0f;
        _waveView.secondaryWaveLineWidth = 1.0f;
        [self addSubview:_waveView];
        
        [_tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self);
            make.top.equalTo(self);
            make.height.equalTo(@(500));
        }];
        
        [_stateLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self).offset(5);
            make.trailing.equalTo(self).offset(-5);
            make.top.equalTo(_tableView.mas_bottom).offset(5);
            make.height.equalTo(@(60));
        }];
        
        [_waveView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self);
            make.bottom.equalTo(self).offset(0);
            make.height.equalTo(@(80));
        }];
        
        [_spectrumView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self);
            make.bottom.equalTo(_waveView.mas_top).offset(0);
            make.height.equalTo(@(100));
        }];
        
        [_meterView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self);
            make.bottom.equalTo(_spectrumView.mas_top).offset(0);
            make.height.equalTo(@(100));
        }];
        
        _meterView.numOfLevels = 50;
        _meterView.levelWidth = 10;
        [_meterView resetLevelData];
    }
    return self;
}

- (void)updateStateInfo:(NSString *)info
{
    self.stateLabel.text = info;
}

@end
