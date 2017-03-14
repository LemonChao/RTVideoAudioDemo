//
//  RTAVVideoEncoder.h
//  RealTimeAVideo
//
//  Created by iLogiEMAC on 16/8/3.
//  Copyright © 2016年 zp. All rights reserved.
//

#import <Foundation/Foundation.h>
@import VideoToolbox;
@class RTAVVideoConfiguration;
@interface RTAVVideoEncoder : NSObject
- (nullable instancetype)initWithVideoConfiguration:(nullable RTAVVideoConfiguration *)configuration;

- (void)encoderVideoData:(CVPixelBufferRef)pixelBuffer timeStamp:(int64_t)timestamp;

// captureSession被call，alarm 打断恢复后，默认重新启动，但是这个压缩编码器 compressEncoder 不存在了，重新创建

- (void)compressSessionCreat;

- (void)compressSessionIncalid;

@end
