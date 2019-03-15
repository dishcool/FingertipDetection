//
//  ViewController.m
//  FingertipDetection
//
//  Created by jianing on 03/11/2016.
//  Copyright © 2016 jianing. All rights reserved.
//

#import "ViewController.h"
#import "ImageProcess.h"

@interface ViewController ()

// 稳定最高点
@property (nonatomic, assign) CGPoint topPoint;
// 实时最高点
@property (nonatomic, assign) CGPoint actualPoint;
// 1秒范围矩形
@property (nonatomic, assign) CGRect rect;

@property (nonatomic, assign) BOOL photoMode;

@property (nonatomic, strong) UIView *redCenter;

@end

@implementation ViewController

@synthesize imageView;
@synthesize photoView;
@synthesize videoCamera;
@synthesize fingerLabel;
@synthesize fingerImageView;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.alpha = 1.f;
    self.photoView.contentMode = UIViewContentModeScaleAspectFit;
    self.photoView.alpha = 1.f;

    self.videoCamera = [[CvVideoCamera alloc]
                        initWithParentView:imageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition =
    AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset =
    AVCaptureSessionPreset1280x720;
    self.videoCamera.defaultAVCaptureVideoOrientation =
    AVCaptureVideoOrientationLandscapeRight;
    self.videoCamera.defaultFPS = 10;
    
    fingerDetect = new FingerDetect();
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - CvVideoCameraDelegate
- (void)processImage:(cv::Mat&)image
{
    // 拍照模式下不处理
    if (image.rows > 720) {
        if (self.photoMode) {
            [self handlePhotoImage:image];
        }
        return;
    }
    
    cv::Point point;
    fingerDetect->detectFinger(image, point);
    fingerDetect->showLines = showLines;
    
    [self handleActualTopPoint:CGPointMake(point.x, point.y)];

}

#pragma mark - CvPhotoCameraDelegate
- (void)handlePhotoImage:(cv::Mat&)image {
    [self.videoCamera stop];
    self.videoCamera.defaultAVCaptureSessionPreset =
    AVCaptureSessionPreset1280x720;
    [self.videoCamera start];
    self.photoMode = false;

    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *captureImage = [ImageProcess cvtImageMat2UIImage:image];
        NSLog(@"截获实时照片 长：%@， 宽：%@", @(captureImage.size.width), @(captureImage.size.height));
        
        CGPoint point = CGPointMake(self.topPoint.x * 3840.f / self.imageView.bounds.size.width, self.topPoint.y * 2160.f / self.imageView.bounds.size.height);
        UIImage *cropImage = [ImageProcess cropSquareImageWithCenterPoint:point sourceImage:captureImage];
        if (cropImage) {
            self.photoView.image = cropImage;
            [self.photoView sizeToFit];
            
            CGRect frame = self.photoView.frame;
            frame.origin = CGPointZero;
            self.photoView.frame = frame;
        }
    });
}

- (void)handleActualTopPoint:(CGPoint)point {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (CGPointEqualToPoint(point, CGPointZero)) {
            // 无效点 返回
            self.redCenter.alpha = 0;
            return;
        }
        self.actualPoint = CGPointMake(point.x * self.imageView.bounds.size.width / 1280.0, point.y * self.imageView.bounds.size.height / 720.0);
        [self handleRectWithActualPoint];
        self.redCenter.center = self.actualPoint;
        self.redCenter.alpha = 1;
    });
}

- (void)handleRectWithActualPoint {
    static int times = 0;
    times += 1;
    if (CGPointEqualToPoint(self.actualPoint, CGPointZero)) {
        // 无效点 返回
        return;
    } else if (CGRectEqualToRect(self.rect, CGRectZero)) {
        self.rect = CGRectMake(self.actualPoint.x, self.actualPoint.y, 0, 0);
        return;
    } else if (!CGRectContainsPoint(self.rect, self.actualPoint)) {
        if (self.actualPoint.x > CGRectGetMaxX(self.rect)) {
            self.rect = CGRectMake(self.rect.origin.x, self.rect.origin.y, self.actualPoint.x - CGRectGetMinX(self.rect), self.rect.size.height);
        } else if ((self.actualPoint.x < CGRectGetMinX(self.rect))) {
            self.rect = CGRectMake(self.actualPoint.x, self.rect.origin.y, CGRectGetMaxX(self.rect) - self.actualPoint.x, self.rect.size.height);
        }
        
        if (self.actualPoint.y > CGRectGetMaxY(self.rect)) {
            self.rect = CGRectMake(self.rect.origin.x, self.rect.origin.y, self.rect.size.width, self.actualPoint.y - CGRectGetMinY(self.rect));
        } else if ((self.actualPoint.y < CGRectGetMinY(self.rect))) {
            self.rect = CGRectMake(self.rect.origin.x, self.actualPoint.y, self.rect.size.width, CGRectGetMaxY(self.rect) - self.actualPoint.y);
        }
    }
    
    if (times > 10) {
        times = 0;
        [self calculateStablePoint];
    }
}

- (void)calculateStablePoint {
    double width = self.rect.size.width;
    double height = self.rect.size.height;

    if (width < 8 && height < 8) {
        // stable
        if (fabs(self.topPoint.x - self.actualPoint.x) < 8 &&
            fabs(self.topPoint.y - self.actualPoint.y) < 8 ) {
            //本次结果和上次相近 不做更新（可能是用户手指较长时间不动）
            return;
        } else {
            self.topPoint = self.actualPoint;
            NSLog(@"还算稳定的位置： %@， %@", @(self.topPoint.x), @(self.topPoint.y));

            self.photoMode = true;
            
            [self.videoCamera stop];
            self.videoCamera.defaultAVCaptureSessionPreset =
            AVCaptureSessionPreset3840x2160;
            [self.videoCamera start];
        }
    } else {
        // reset
        self.topPoint = CGPointZero;
        self.rect = CGRectZero;
        self.photoView.image = nil;
    }
}

- (void)dealloc
{
    videoCamera.delegate = nil;
}

- (IBAction)detectSwitchTapped:(id)sender {
    BOOL isOn = [sender isOn];
    if (isOn) {
        [videoCamera start];
    } else {
        [videoCamera stop];
    }
}

- (IBAction)showLinesSwitchTapped:(id)sender {
    showLines = [sender isOn];
}

- (UIView *)redCenter {
    if (!_redCenter) {
        _redCenter = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        _redCenter.backgroundColor = [UIColor redColor];
        _redCenter.layer.cornerRadius = 5;
        _redCenter.layer.masksToBounds = YES;
        [self.imageView addSubview:_redCenter];
    }
    return _redCenter;
}

@end
