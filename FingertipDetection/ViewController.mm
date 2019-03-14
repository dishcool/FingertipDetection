//
//  ViewController.m
//  FingertipDetection
//
//  Created by jianing on 03/11/2016.
//  Copyright © 2016 jianing. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

// 稳定最高点
@property (nonatomic, assign) CGPoint topPoint;
// 实时最高点
@property (nonatomic, assign) CGPoint actualPoint;

@property (nonatomic, strong) UIView *redCenter;

@end

@implementation ViewController

@synthesize imageView;
@synthesize videoCamera;
@synthesize fingerLabel;
@synthesize fingerImageView;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    self.videoCamera = [[CvVideoCamera alloc]
                        initWithParentView:imageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition =
    AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset =
    AVCaptureSessionPreset640x480;
    self.videoCamera.defaultAVCaptureVideoOrientation =
    AVCaptureVideoOrientationLandscapeRight;
    self.videoCamera.defaultFPS = 30;
    
    fingerDetect = new FingerDetect();
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)processImage:(cv::Mat&)image
{
    cv::Point point;
    fingerDetect->detectFinger(image, point);
    fingerDetect->showLines = showLines;
    
    [self handleActualTopPoint:CGPointMake(point.x, point.y)];
}

- (void)handleActualTopPoint:(CGPoint)point {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.actualPoint = CGPointMake(point.x * self.imageView.bounds.size.width / 640.0, point.y * self.imageView.bounds.size.height / 480.0);
        self.redCenter.center = self.actualPoint;
    });
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
