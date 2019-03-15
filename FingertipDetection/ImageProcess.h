//
//  ImageProcess.hpp
//  FingertipDetection
//
//  Created by dishcool on 15/3/2019.
//  Copyright © 2019 jianing. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageProcess : NSObject

+ (nonnull UIImage *)cvtImageMat2UIImage:(cv::Mat&)image;

// 以图片中心为中心，以最小边为边长，裁剪长方形图片
+ (UIImage *)cropSquareImageWithCenterPoint:(CGPoint)point sourceImage:(UIImage *)sourceImage;

@end
