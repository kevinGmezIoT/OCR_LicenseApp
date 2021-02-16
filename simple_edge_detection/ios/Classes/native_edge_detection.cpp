#include "native_edge_detection.hpp"
#include "edge_detector.hpp"
#include "image_processor.hpp"
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/imgproc/imgproc.hpp"
#include <stdlib.h>
#include <opencv2/opencv.hpp>
#include <opencv2/imgproc/types_c.h>


extern "C" __attribute__((visibility("default"))) __attribute__((used))
struct Coordinate *create_coordinate(double x, double y)
{
    struct Coordinate *coordinate = (struct Coordinate *)malloc(sizeof(struct Coordinate));
    coordinate->x = x;
    coordinate->y = y;
    return coordinate;
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
struct DetectionResult *create_detection_result(Coordinate *topLeft, Coordinate *topRight, Coordinate *bottomLeft, Coordinate *bottomRight)
{
    struct DetectionResult *detectionResult = (struct DetectionResult *)malloc(sizeof(struct DetectionResult));
    detectionResult->topLeft = topLeft;
    detectionResult->topRight = topRight;
    detectionResult->bottomLeft = bottomLeft;
    detectionResult->bottomRight = bottomRight;
    return detectionResult;
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
struct DetectionResult *detect_edges(char *str) {
    struct DetectionResult *coordinate = (struct DetectionResult *)malloc(sizeof(struct DetectionResult));
    cv::Mat mat = cv::imread(str);

    if (mat.size().width == 0 || mat.size().height == 0) {
        return create_detection_result(
            create_coordinate(0, 0),
            create_coordinate(1, 0),
            create_coordinate(0, 1),
            create_coordinate(1, 1)
        );
    }

    vector<cv::Point> points = EdgeDetector::detect_edges(mat);

    return create_detection_result(
        create_coordinate((double)points[0].x / mat.size().width, (double)points[0].y / mat.size().height),
        create_coordinate((double)points[1].x / mat.size().width, (double)points[1].y / mat.size().height),
        create_coordinate((double)points[2].x / mat.size().width, (double)points[2].y / mat.size().height),
        create_coordinate((double)points[3].x / mat.size().width, (double)points[3].y / mat.size().height)
    );
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
char *image_warp(char *str,char *out, int x1, int y1, int x2, int y2, int x4, int y4, int x3, int y3 ) {
        
    // Input Quadilateral or Image plane coordinates
    Point2f inputQuad[4];
    // Output Quadilateral or World plane coordinates
    Point2f outputQuad[4];

    // Lambda Matrix
    Mat lambda(2, 4, CV_32FC1);
    //Input and Output Image;
    Mat input, output;
    //Size
    Size size(600, 380);

    //Load the image
    input = imread(str, 1);
    // Set the lambda matrix the same type and size as input
    lambda = Mat::zeros(input.rows, input.cols, input.type());
    
    // The 4 points that select quadilateral on the input , from top-left in clockwise order
    // These four pts are the sides of the rect box used as input 
    inputQuad[0] = Point2f(x1, y1);
    inputQuad[1] = Point2f(x2, y2);
    inputQuad[2] = Point2f(x4, y4);
    inputQuad[3] = Point2f(x3, y3);
    // The 4 points where the mapping is to be done , from top-left in clockwise order
    outputQuad[0] = Point2f(0, 0);
    outputQuad[1] = Point2f(600, 0);
    outputQuad[2] = Point2f(600, 380);
    outputQuad[3] = Point2f(0, 380);

    // Get the Perspective Transform Matrix i.e. lambda 
    lambda = getPerspectiveTransform(inputQuad, outputQuad);
    // Apply the Perspective Transform just found to the src image
    warpPerspective(input, output, lambda, size);

    //Clean Image:
    //Input and Output Image;
    Mat clean_output,process, topHat, blackHat;        

    cvtColor(output,process,COLOR_BGR2GRAY);

    Mat kernel = getStructuringElement(MORPH_RECT,Size(3,3));

    morphologyEx(process, topHat, MORPH_TOPHAT, kernel);
    morphologyEx(process, blackHat, MORPH_BLACKHAT, kernel);

    add(process, topHat, topHat);
    subtract(topHat,blackHat,clean_output);

    cv::imwrite(out, clean_output);
    return out;
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
char *image_merge(char *str1, char *str2, char *str3, char *str4, char *str5, char *out) {
        
    //Input and Output Image;
    Mat input1, input2, input3, input4, input5, output;    

    //Load the image
    input1 = imread(str1, 1);
    input2 = imread(str2, 1);
    input3 = imread(str3, 1);
    input4 = imread(str4, 1);
    input5 = imread(str5, 1);

    if (input1.empty() || input2.empty() || input3.empty() || input4.empty() || input5.empty())
    {        
        return out;
    }

    cv::resize(input2, input2, Size(input1.cols, input2.rows* input1.cols/input2.cols));
    cv::resize(input3, input3, Size(input1.cols, input3.rows* input1.cols/input3.cols));
    cv::resize(input4, input4, Size(input1.cols, input4.rows* input1.cols/input4.cols));
    cv::resize(input5, input5, Size(input1.cols, input5.rows* input1.cols/input5.cols));
    
    cv::vconcat(input1, input2, output);
    cv::vconcat(output, input3, output);
    cv::vconcat(output, input4, output);
    cv::vconcat(output, input5, output);

    cv::imwrite(out, output);
    return out;
}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
struct DetectionResult *image_processing(char *str, char *out, char *out_merged,
                                        int roi00, int roi01, int roi02, int roi03,
                                        int roi10, int roi11, int roi12, int roi13,
                                        int roi20, int roi21, int roi22, int roi23,
                                        int roi30, int roi31, int roi32, int roi33,
                                        int roi40, int roi41, int roi42, int roi43) {

    struct DetectionResult *coordinate = (struct DetectionResult *)malloc(sizeof(struct DetectionResult));
    
    cv::Mat mat = cv::imread(str, IMREAD_COLOR);

    if (mat.size().width == 0 || mat.size().height == 0) {
        return create_detection_result(
            create_coordinate(0, 0),
            create_coordinate(1, 0),
            create_coordinate(0, 1),
            create_coordinate(1, 1)
        );
    }

    // Input Quadilateral or Image plane coordinates
    Point2f inputQuad[4];
    // Output Quadilateral or World plane coordinates
    Point2f outputQuad[4];

    // Lambda Matrix
    Mat lambda(2, 4, CV_32FC1);
    //Input and Output Image;
    Mat input, output, concat_output;
    //Size
    Size size(600, 380);

    //Load the image
    input = cv::imread(str,1);
    
    // Set the lambda matrix the same type and size as input
    lambda = Mat::zeros(input.rows, input.cols, input.type());

    vector<cv::Point> points = EdgeDetector::detect_edges(mat);       
    
    // The 4 points that select quadilateral on the input , from top-left in clockwise order
    // These four pts are the sides of the rect box used as input 
    inputQuad[0] = Point2f((double)points[0].x, (double)points[0].y);
    inputQuad[1] = Point2f((double)points[1].x, (double)points[1].y);
    inputQuad[2] = Point2f((double)points[3].x, (double)points[3].y);
    inputQuad[3] = Point2f((double)points[2].x, (double)points[2].y);
    // The 4 points where the mapping is to be done , from top-left in clockwise order
    outputQuad[0] = Point2f(0, 0);
    outputQuad[1] = Point2f(600, 0);
    outputQuad[2] = Point2f(600, 380);
    outputQuad[3] = Point2f(0, 380);
    
    // Get the Perspective Transform Matrix i.e. lambda 
    lambda = getPerspectiveTransform(inputQuad, outputQuad);
    // Apply the Perspective Transform just found to the src image
    warpPerspective(input, output, lambda, size);

    //Clean Image:
    //Input and Output Image;
    Mat clean_output,process, topHat, blackHat;        

    cvtColor(output,process,COLOR_BGR2GRAY);
    
    Mat kernel = getStructuringElement(MORPH_RECT,Size(3,3));

    morphologyEx(process, topHat, MORPH_TOPHAT, kernel);
    morphologyEx(process, blackHat, MORPH_BLACKHAT, kernel);

    add(process, topHat, topHat);
    subtract(topHat,blackHat,clean_output);

    cv::imwrite(out, clean_output);
    
    cv::Rect myROI1(roi00, roi01, roi02, roi03);
    cv::Rect myROI2(roi10, roi11, roi12, roi13);
    cv::Rect myROI3(roi20, roi21, roi22, roi23);
    cv::Rect myROI4(roi30, roi31, roi32, roi33);
    cv::Rect myROI5(roi40, roi41, roi42, roi43);

    cv::Mat feature1 = clean_output(myROI1);
    cv::Mat feature2 = clean_output(myROI2);
    cv::Mat feature3 = clean_output(myROI3);
    cv::Mat feature4 = clean_output(myROI4);
    cv::Mat feature5 = clean_output(myROI5);

    cv::resize(feature2, feature2, Size(feature1.cols, feature2.rows* feature1.cols/feature2.cols));
    cv::resize(feature3, feature3, Size(feature1.cols, feature3.rows* feature1.cols/feature3.cols));
    cv::resize(feature4, feature4, Size(feature1.cols, feature4.rows* feature1.cols/feature4.cols));
    cv::resize(feature5, feature5, Size(feature1.cols, feature5.rows* feature1.cols/feature5.cols));
    
    cv::vconcat(feature1, feature2, concat_output);
    cv::vconcat(concat_output, feature3, concat_output);
    cv::vconcat(concat_output, feature4, concat_output);
    cv::vconcat(concat_output, feature5, concat_output);

    cv::imwrite(out_merged, concat_output);
    
    return create_detection_result(
        create_coordinate((double)points[0].x / mat.size().width, (double)points[0].y / mat.size().height),
        create_coordinate((double)points[1].x / mat.size().width, (double)points[1].y / mat.size().height),
        create_coordinate((double)points[2].x / mat.size().width, (double)points[2].y / mat.size().height),
        create_coordinate((double)points[3].x / mat.size().width, (double)points[3].y / mat.size().height)
    );

}

extern "C" __attribute__((visibility("default"))) __attribute__((used))
bool process_image(
    char *path,
    double topLeftX,
    double topLeftY,
    double topRightX,
    double topRightY,
    double bottomLeftX,
    double bottomLeftY,
    double bottomRightX,
    double bottomRightY
) {
    cv::Mat mat = cv::imread(path);

    cv::Mat resizedMat = ImageProcessor::process_image(
        mat,
        topLeftX * mat.size().width,
        topLeftY * mat.size().height,
        topRightX * mat.size().width,
        topRightY * mat.size().height,
        bottomLeftX * mat.size().width,
        bottomLeftY * mat.size().height,
        bottomRightX * mat.size().width,
        bottomRightY * mat.size().height
    );

    return cv::imwrite(path, resizedMat);
}