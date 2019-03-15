//
//  ImageProcess.cpp
//  FingertipDetection
//
//  Created by dishcool on 15/3/2019.
//  Copyright © 2019 jianing. All rights reserved.
//

#import <vector>
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc.hpp>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include "ImageProcess.h"


/// Converts a Mat to UIImage.
static UIImage *MatToUIImage(cv::Mat &mat) {
    
    // Change a image format.
    NSData *data = [NSData dataWithBytes:mat.data length:(mat.elemSize() * mat.total())];
    CGColorSpaceRef colorSpace;
    if (mat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(mat.cols, mat.rows, 8, 8 * mat.elemSize(), mat.step.p[0], colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return image;
    
}


@implementation ImageProcess

+ (nonnull UIImage *)cvtImageMat2UIImage:(cv::Mat&)image {
    return MatToUIImage(image);
}


// 以图片中心为中心，以最小边为边长，裁剪长方形图片
+ (UIImage *)cropSquareImageWithCenterPoint:(CGPoint)point sourceImage:(UIImage *)sourceImage {
    
    CGImageRef sourceImageRef = [sourceImage CGImage];//将UIImage转换成CGImageRef
    
    CGFloat _imageWidth = sourceImage.size.width * sourceImage.scale;
    CGFloat _imageHeight = sourceImage.size.height * sourceImage.scale;
    double _pointX = point.x * sourceImage.scale;
    double _pointY = point.y * sourceImage.scale;
    
    CGFloat _width = 300 * sourceImage.scale;
    CGFloat _height = 150 * sourceImage.scale;
    CGFloat _offsetX = _pointX - _width * 0.5f;
    CGFloat _offsetY = _pointY - _height;
    
    CGRect rect = CGRectMake(_offsetX, _offsetY, _width, _height);
    
    if (CGRectContainsRect(CGRectMake(0, 0, _imageWidth, _imageHeight), rect)) {
        CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);//按照给定的矩形区域进行剪裁
        return [UIImage imageWithCGImage:newImageRef];
    }
    return nil;
}
@end


