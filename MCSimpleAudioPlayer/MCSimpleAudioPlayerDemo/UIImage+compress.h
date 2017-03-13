//
//  UIImage+compress.h
//  MCSimpleAudioPlayerDemo
//
//  Created by Lemon on 17/3/8.
//  Copyright © 2017年 Chengyin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (compress)

//图片压缩到指定大小
- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize;


/**
 压图片质量
 
 @param image image
 @return Data
 */
+ (NSData *)zipImageWithImage:(UIImage *)image;

@end
