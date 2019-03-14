
#pragma once

#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>

class FingerDetect
{
public:
    // 手指识别 并找到手指最高位置
    int detectFinger(cv::Mat& frame, cv::Point& topPoint);
    float innerAngle(float px1, float py1, float px2, float py2, float cx1, float cy1);
    bool showLines = false;
};
