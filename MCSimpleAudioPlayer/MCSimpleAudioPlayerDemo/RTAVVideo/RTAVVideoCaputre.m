//
//  RTAVVideoCaputre.m
//  RealTimeAVideo
//
//  Created by iLogiEMAC on 16/8/3.
//  Copyright © 2016年 zp. All rights reserved.
//

#import "RTAVVideoCaputre.h"
#import "RTAVVideoConfiguration.h"
#import "RTAVVideoEncoder.h"
#import <AssetsLibrary/AssetsLibrary.h>
@interface RTAVVideoCaputre ()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureVideoPreviewLayer * _preViewLayer;
    
}
@property (nonatomic,strong)RTAVVideoEncoder *videoEncoder;
@property (nonatomic,strong)AVCaptureSession *session;
@property (nonatomic,strong)RTAVVideoConfiguration *videoConfiguration;
/** 图片输出流*/
@property (nonatomic, strong) AVCaptureStillImageOutput* stillImageOutput;


@end
@implementation RTAVVideoCaputre

- (instancetype)initWithVideoConfiguration:(RTAVVideoConfiguration *)configuration
{
    if (self = [super init]) {
        _videoConfiguration = configuration;

        [self addPreVideo];
    }
    return self;
}
#pragma mark - Method

- (void)captureSessionWasInterrupt:(NSNotification *)notif {
    DLog(@"notif = %@", notif);
    NSDictionary *notiInfo = notif.userInfo;

    AVCaptureSessionInterruptionReason reason =  [notiInfo[AVCaptureSessionInterruptionReasonKey] integerValue];
    if (reason == AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableInBackground) {
        //encoder pause
        [self.videoEncoder compressSessionIncalid];
    }
}

- (void)sessionInterruptionEnded:(NSNotification *)notif {
    DLog(@"notif = %@", notif);
    [self.videoEncoder compressSessionCreat];
    
}

- (void)sessionDidStopRunning:(NSNotification *)notif {
    DLog(@"notif = %@", notif);
}

- (void)sessionDidStartRunning:(NSNotification *)notif {
    DLog(@"notif = %@", notif);
}


- (void)addPreVideo
{
    AVCaptureVideoPreviewLayer * preViewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    preViewLayer.frame = [UIScreen mainScreen].bounds;
    preViewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    _preViewLayer = preViewLayer;
    
}

#pragma mark - delegate

#pragma mark AVCaptureSessionDelegete
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer  = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (imageBuffer != NULL) {
        
        [self.videoEncoder encoderVideoData:imageBuffer timeStamp:0];
    }
}


-(RTAVVideoEncoder *)videoEncoder
{
    if (!_videoEncoder) {
        RTAVVideoEncoder * encoder = [[RTAVVideoEncoder alloc]initWithVideoConfiguration:_videoConfiguration];
        _videoEncoder = encoder;
    }
    return _videoEncoder;
}

#pragma mark - setter & getter
- (AVCaptureSession *)session
{
    if (!_session) {
        //4.
        AVCaptureSession * session = [[AVCaptureSession alloc]init];
        session.sessionPreset = _videoConfiguration.avsessionPreset;
       
        //Session 被打断
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionWasInterrupt:) name:AVCaptureSessionWasInterruptedNotification object:session];
        //session 打断结束
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:session];
        //session 已经停止
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionDidStopRunning:) name:AVCaptureSessionDidStopRunningNotification object:session];
        //session 已经运转
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionDidStartRunning:) name:AVCaptureSessionDidStartRunningNotification object:session];
        
        //1.
        AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        NSError * error = nil;
        //2.
        AVCaptureDeviceInput * videoInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
      
        //3.
        AVCaptureVideoDataOutput *  videoOutput = [[AVCaptureVideoDataOutput alloc]init];
        dispatch_queue_t videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
        [videoOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];

//        videoOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
        
    
        //5.
        self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
        //添加照片输出
        [self.stillImageOutput setOutputSettings:outputSettings];
        
        if ([session canAddOutput:self.stillImageOutput]) {
            [session addOutput:self.stillImageOutput];
        }

        if ([session canAddInput:videoInput]) {
            [session addInput:videoInput];
        }
        if ([session canAddOutput:videoOutput]) {
            [session addOutput:videoOutput];
        }
        
        //此设置要放到addDeviceInput之后才能获取到
        AVCaptureConnection * connection =  [videoOutput connectionWithMediaType:AVMediaTypeVideo] ;
        
        UIInterfaceOrientation statusBar = [[UIApplication sharedApplication] statusBarOrientation];
        if(_videoConfiguration.landscape){
            if(statusBar != UIInterfaceOrientationLandscapeLeft && statusBar != UIInterfaceOrientationLandscapeRight){
                NSLog(@"当前设置方向出错");
                NSLog(@"当前设置方向出错");
                NSLog(@"当前设置方向出错");
                if (connection.isVideoOrientationSupported) {
                    [connection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
                }
            }else{
                
                if (connection.isVideoOrientationSupported) {
                    [connection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
                }
            }
        }else{
            if(statusBar != UIInterfaceOrientationPortrait && statusBar != UIInterfaceOrientationPortraitUpsideDown){
                NSLog(@"当前设置方向出错");
                NSLog(@"当前设置方向出错");
                NSLog(@"当前设置方向出错");
                if (connection.isVideoOrientationSupported) {
                    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
                }
            }else{
                if (connection.isVideoOrientationSupported) {
                    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
                }
            }
        }
        //设置帧率
        if ([device respondsToSelector:@selector(setActiveVideoMaxFrameDuration:)] && [device respondsToSelector:@selector(setActiveVideoMinFrameDuration:)]) {
            NSError * error ;
            if (nil == error) {
#if defined (__IPHONE_7_0)
             CMTime videoFrameRate =  CMTimeMake(1, (int32_t)_videoConfiguration.videoFrameRate);
                NSArray *supportedFrameRateRanges = [device.activeFormat videoSupportedFrameRateRanges];
                BOOL frameRateSupported = NO;
                for (AVFrameRateRange *range in supportedFrameRateRanges) {
                    if (CMTIME_COMPARE_INLINE(videoFrameRate, >=, range.minFrameDuration) &&
                        CMTIME_COMPARE_INLINE(videoFrameRate, <=, range.maxFrameDuration)) {
                        frameRateSupported = YES;
                    }
                }
                if (frameRateSupported && [device lockForConfiguration:&error]) {
                    device.activeVideoMaxFrameDuration = videoFrameRate;
                    device.activeVideoMinFrameDuration = videoFrameRate;
                    [device unlockForConfiguration];
                }
#endif
            }
        }else
        {
            for (AVCaptureConnection * connection in videoOutput.connections) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                if ([connection respondsToSelector:@selector(setVideoMinFrameDuration:)])
                    connection.videoMinFrameDuration = CMTimeMake(1,  (int32_t)_videoConfiguration.videoMinFrameRate);
                
                if ([connection respondsToSelector:@selector(setVideoMaxFrameDuration:)])
                    connection.videoMaxFrameDuration = CMTimeMake(1, (int32_t)_videoConfiguration.videoMaxFrameRate);
#pragma clang diagnostic pop
            }
        }

        
        //光学防抖
        AVCaptureVideoStabilizationMode stabilizationMode = AVCaptureVideoStabilizationModeCinematic;
        if ([device.activeFormat isVideoStabilizationModeSupported:stabilizationMode]) {
            [connection setPreferredVideoStabilizationMode:stabilizationMode];
        }
        
        _session = session;
        
    }
    return _session;
}
- (void)setPreView:(UIView *)preView
{
    _preView = preView;
    if (_preViewLayer.superlayer ) {
        [_preViewLayer removeFromSuperlayer];
    }
    if (_preViewLayer) {
        [preView.layer addSublayer:_preViewLayer];
    }

}
- (void)setRuning:(BOOL)runing
{
    if (_runing == runing) return;
    
    _runing = runing;
    
    if (runing) {
        [self.session  startRunning];
    }else
    {
        [self.session stopRunning];
    }
}

//-------new
/** 点击拍照 */
- (void)takePhotoButtonClick
{
    
    
     //添加了切换分辨率, 高分辨率图片压缩
     [self changeSessionPresentPhoto];
     AVCaptureConnection *stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
     UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
     AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
     [stillImageConnection setVideoOrientation:avcaptureOrientation];
     //    [stillImageConnection setVideoScaleAndCropFactor:self.effectiveScale];
     
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.50 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
     
     [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
         
         
         [self changeSessionPresentVideo];
         
         NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
         CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
                                                                     imageDataSampleBuffer,
                                                                     kCMAttachmentMode_ShouldPropagate);
         
         ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
         if (author == ALAuthorizationStatusRestricted || author == ALAuthorizationStatusDenied){
             //无权限
             NSLog(@"没有权限");
             
             return ;
         }
         

         
         NSData *compressData = [UIImage zipImageWithImage:[UIImage imageWithData:jpegData]];

         
         
         ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
         [library writeImageDataToSavedPhotosAlbum:jpegData metadata:(__bridge id)attachments completionBlock:^(NSURL *assetURL, NSError *error) {
         }];
         
         [library writeImageDataToSavedPhotosAlbum:compressData metadata:(__bridge id)attachments completionBlock:^(NSURL *assetURL, NSError *error) {
         }];

//         [library writeImageToSavedPhotosAlbum:<#(CGImageRef)#> metadata:<#(NSDictionary *)#> completionBlock:<#^(NSURL *assetURL, NSError *error)completionBlock#>]
         
//         [library writeImageToSavedPhotosAlbum:<#(CGImageRef)#> orientation:<#(ALAssetOrientation)#> completionBlock:<#^(NSURL *assetURL, NSError *error)completionBlock#>]

     
     }];
  });

    
    
//    self.session.sessionPreset = AVCaptureSessionPreset640x480; //AVCaptureSessionPreset1280x720
//    NSLog(@"takephotoClick...");
//    AVCaptureConnection *stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
//    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
//    AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
//    [stillImageConnection setVideoOrientation:avcaptureOrientation];
//    //        [stillImageConnection setVideoScaleAndCropFactor:self.effectiveScale];
//    
//    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
//        
//        self.session.sessionPreset = AVCaptureSessionPreset1280x720;
//        
//        NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
//        CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
//                                                                    imageDataSampleBuffer,
//                                                                    kCMAttachmentMode_ShouldPropagate);
//        
//        ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
//        if (author == ALAuthorizationStatusRestricted || author == ALAuthorizationStatusDenied){
//            //无权限
//            NSLog(@"没有权限");
//            return ;
//        }
//        
//        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//        [library writeImageDataToSavedPhotosAlbum:jpegData metadata:(__bridge id)attachments completionBlock:^(NSURL *assetURL, NSError *error) {
//        }];
//        
//        
//    }];
    
    
}


/** 设备捕获方向*/
- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
        result = AVCaptureVideoOrientationLandscapeRight;
    else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
        result = AVCaptureVideoOrientationLandscapeLeft;
    return result;
}

/** 切换到拍照分辨率*/
- (void)changeSessionPresentPhoto
{
    
    [self.session stopRunning];
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
        self.session.sessionPreset = AVCaptureSessionPreset1920x1080;
    }else {
        self.session.sessionPreset = AVCaptureSessionPreset640x480;
        
    }
    NSLog(@"%@",self.session.sessionPreset);
    [self.session startRunning];
    //    usleep(2000);
}
/** 切换到视频分辨率*/
- (void)changeSessionPresentVideo
{
    [self.session stopRunning];
    
    self.session.sessionPreset = AVCaptureSessionPreset640x480;
    
    NSLog(@"%@",self.session.sessionPreset);
    [self.session startRunning];
    //    usleep(2000);
    
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionWasInterruptedNotification object:self.session];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionInterruptionEndedNotification object:self.session];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionDidStartRunningNotification object:self.session];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionDidStopRunningNotification object:self.session];

}

@end
