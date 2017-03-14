//
//  RTAVSession.m
//  RealTimeAVideo
//
//  Created by iLogiEMAC on 16/8/3.
//  Copyright © 2016年 zp. All rights reserved.
//

#import "RTAVSession.h"
#import "RTAVVideoCaputre.h"
@interface RTAVSession ()
@property (nonatomic,strong)RTAVVideoCaputre *videoCapture;
@property (nonatomic,strong)RTAVVideoConfiguration *configuration;
@end

@implementation RTAVSession

- (instancetype)initWithRTAVVideoConfiguration:(RTAVVideoConfiguration *)configuration;
{
    if (self= [super init]) {
        _configuration = configuration;
    }
    return  self;
}

#pragma mark - setter & getter
- (void)setRunning:(BOOL)running
{
    if (_running == running) return;
    _running = running;
    self.videoCapture.runing = running;
}


- (RTAVVideoCaputre *)videoCapture
{
    if (!_videoCapture) {
        RTAVVideoCaputre * videoCapture = [[RTAVVideoCaputre alloc]initWithVideoConfiguration:_configuration];
        _videoCapture = videoCapture;
    }
    return _videoCapture;
}
- (void)setPreView:(UIView *)preView
{
    _preView = preView;
    self.videoCapture.preView = preView;
}

/** 坐席主动拍照 */
- (void)takePholtoWithParam {
    [self.videoCapture takePhotoButtonClick];
}


@end
