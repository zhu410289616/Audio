//
//  CCDRecorderView.m
//  Cicada
//
//  Created by ruhong zhu on 2020/8/2.
//

#import "CCDRecorderView.h"

@implementation CCDRecorderView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor lightGrayColor];
        
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton setTitle:@"play" forState:UIControlStateNormal];
        [self addSubview:_playButton];
        
        _soundTouchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_soundTouchButton setTitle:@"sound touch" forState:UIControlStateNormal];
        [self addSubview:_soundTouchButton];
        
        _recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        _recordButton.frame = CGRectMake(20, 170, 150, 50);
        [_recordButton setTitle:@"record" forState:UIControlStateNormal];
        [self addSubview:_recordButton];
        
        _mp3RecordButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        _mp3RecordButton.frame = CGRectMake(20, 230, 150, 50);
        [_mp3RecordButton setTitle:@"mp3 record" forState:UIControlStateNormal];
        [self addSubview:_mp3RecordButton];
        
        _auRecordButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        _auRecordButton.frame = CGRectMake(20, 280, 150, 50);
        [_auRecordButton setTitle:@"AU record" forState:UIControlStateNormal];
        [self addSubview:_auRecordButton];
        
        _meterView = [[CCDAudioRecordMeterView alloc] initWithFrame:CGRectZero];
        [self addSubview:_meterView];
        
        [_playButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self).offset(20);
            make.top.equalTo(self).offset(50);
            make.size.mas_equalTo(CGSizeMake(150, 50));
        }];
        
        [_soundTouchButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self).offset(20);
            make.top.equalTo(_playButton.mas_bottom).offset(20);
            make.size.mas_equalTo(CGSizeMake(150, 50));
        }];
        
        [_recordButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self).offset(20);
            make.top.equalTo(_soundTouchButton.mas_bottom).offset(20);
            make.size.mas_equalTo(CGSizeMake(150, 50));
        }];
        
        [_mp3RecordButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self).offset(20);
            make.top.equalTo(_recordButton.mas_bottom).offset(10);
            make.size.mas_equalTo(CGSizeMake(150, 50));
        }];
        
        [_auRecordButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self).offset(20);
            make.top.equalTo(_mp3RecordButton.mas_bottom).offset(10);
            make.size.mas_equalTo(CGSizeMake(150, 50));
        }];
        
        [_meterView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self);
            make.bottom.equalTo(self);
            make.height.equalTo(@(200));
        }];
        
        _meterView.numOfLevels = 50;
        _meterView.levelWidth = 10;
        [_meterView resetLevelData];
    }
    return self;
}

@end
