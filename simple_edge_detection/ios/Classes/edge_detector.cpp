#include "edge_detector.hpp"

#include <opencv2/opencv.hpp>
#include <opencv2/imgproc/types_c.h>

using namespace cv;
using namespace std;

// helper function:
// finds a cosine of angle between vectors
// from pt0->pt1 and from pt0->pt2
double EdgeDetector::get_cosine_angle_between_vectors(cv::Point pt1, cv::Point pt2, cv::Point pt0)
{
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

vector<cv::Point> image_to_vector(Mat& image)
{
    int imageWidth = image.size().width;
    int imageHeight = image.size().height;

    return {
        cv::Point(0, 0),
        cv::Point(imageWidth, 0),
        cv::Point(0, imageHeight),
        cv::Point(imageWidth, imageHeight)
    };
}

vector<cv::Point> EdgeDetector::detect_edges(Mat& image)
{
    vector<vector<cv::Point>> squares = find_squares(image);
    vector<cv::Point>* biggestSquare = NULL;
    // Sort so that the points are ordered clockwise

    struct sortY {
        bool operator() (cv::Point pt1, cv::Point pt2) { return (pt1.y < pt2.y);}
    } orderRectangleY;
    struct sortX {
        bool operator() (cv::Point pt1, cv::Point pt2) { return (pt1.x < pt2.x);}
    } orderRectangleX;

    for (int i = 0; i < squares.size(); i++) {
        vector<cv::Point>* currentSquare = &squares[i];

        std::sort(currentSquare->begin(),currentSquare->end(), orderRectangleY);
        std::sort(currentSquare->begin(),currentSquare->begin()+2, orderRectangleX);
        std::sort(currentSquare->begin()+2,currentSquare->end(), orderRectangleX);

        float currentSquareWidth = get_width(*currentSquare);
        float currentSquareHeight = get_height(*currentSquare);

        if (currentSquareWidth < image.size().width / 5 || currentSquareHeight < image.size().height / 5) {
            continue;
        }

        if (currentSquareWidth > image.size().width * 0.99 || currentSquareHeight > image.size().height * 0.99) {
            continue;
        }

        if (biggestSquare == NULL) {
            biggestSquare = currentSquare;
            continue;
        }

        float biggestSquareWidth = get_width(*biggestSquare);
        float biggestSquareHeight = get_height(*biggestSquare);

        if (currentSquareWidth * currentSquareHeight >= biggestSquareWidth * biggestSquareHeight) {
            biggestSquare = currentSquare;
        }

    }

    if (biggestSquare == NULL) {
        return image_to_vector(image);
    }

    std::sort(biggestSquare->begin(),biggestSquare->end(), orderRectangleY);
    std::sort(biggestSquare->begin(),biggestSquare->begin()+2, orderRectangleX);
    std::sort(biggestSquare->begin()+2,biggestSquare->end(), orderRectangleX);

    return *biggestSquare;
}

float EdgeDetector::get_height(vector<cv::Point>& square) {
    float upperLeftToLowerRight = square[3].y - square[0].y;
    float upperRightToLowerLeft = square[1].y - square[2].y;

    return max(upperLeftToLowerRight, upperRightToLowerLeft);
}

float EdgeDetector::get_width(vector<cv::Point>& square) {
    float upperLeftToLowerRight = square[3].x - square[0].x;
    float upperRightToLowerLeft = square[1].x - square[2].x;

    return max(upperLeftToLowerRight, upperRightToLowerLeft);
}

cv::Mat EdgeDetector::debug_squares( cv::Mat image )
{
    vector<vector<cv::Point> > squares = find_squares(image);

    for (const auto & square : squares) {
        // draw rotated rect
        cv::RotatedRect minRect = minAreaRect(cv::Mat(square));
        cv::Point2f rect_points[4];
        minRect.points( rect_points );
        for ( int j = 0; j < 4; j++ ) {
            cv::line( image, rect_points[j], rect_points[(j+1)%4], cv::Scalar(0,0,255), 1, 8 ); // blue
        }
    }

    return image;
}

vector<cv::Point> orderPoint(std::vector<Point> const& input)
{
    vector<cv::Point> rect;
    rect.push_back(Point(0, 0));
    rect.push_back(Point(0, 0));
    rect.push_back(Point(0, 0));
    rect.push_back(Point(0, 0));

    vector<float> suma, resta;
    for (int i = 0; i < input.size(); i++) {
        suma.push_back(input.at(i).x + input.at(i).y);
    }
    for (int i = 0; i < suma.size(); i++) {
        cout << suma.at(i);
        cout << endl;
    }

    for (int i = 0; i < input.size(); i++) {
        resta.push_back(input.at(i).x - input.at(i).y);
    }

    cout << min_element(suma.begin(), suma.end())-suma.begin();
    cout << endl;
    cout << max_element(suma.begin(), suma.end())-suma.begin();
    cout << endl;

    rect.at(0) = input.at(min_element(suma.begin(), suma.end()) - suma.begin());
    rect.at(2) = input.at(max_element(suma.begin(), suma.end()) - suma.begin());
    rect.at(1) = input.at(min_element(resta.begin(), resta.end()) - resta.begin());
    rect.at(3) = input.at(max_element(resta.begin(), resta.end()) - resta.begin());

    return rect;
}

vector<vector<cv::Point> > EdgeDetector::find_squares(Mat& image)
{   
   /* 
   int erosion_size = 5;
    cv::Mat bilateral;
    cv::Mat element = cv::getStructuringElement(cv::MORPH_CROSS,
        cv::Size(2 * erosion_size + 1, 2 * erosion_size + 1),
        cv::Point(erosion_size, erosion_size));
    vector<vector<cv::Point> > contours;
    vector<cv::Point> found,approx;

    cvtColor(image, image, COLOR_BGR2GRAY);
    GaussianBlur(image, image, Size(7, 7),0,0,0);
    Canny(image, image, 30, 50, 3);
    dilate(image, image, element);

    findContours(image, contours, RETR_LIST, CV_CHAIN_APPROX_SIMPLE);

    int conteo = 0;
    int iWidth = image.size().width;
    int iHeight = image.size().height;
    int area = iWidth * iHeight;
    
    for (const auto& contour : contours) {
        if (cv::contourArea(contour)>=area*0.4 && cv::contourArea(contour) <= area*0.8) {
            found = contour;
        }        
    }
    
    float epsilon = 0.1 * arcLength(found, true);
    approxPolyDP(found, approx, epsilon, true);
    vector<cv::Point> points = orderPoint(approx);

    RotatedRect minRect = minAreaRect(found);
    Mat boxPts;
    boxPoints(minRect, boxPts);

    vector<Point> vBoxPts, cornerPts;

    for (int y = 0; y < boxPts.rows; y++) {
        vBoxPts.push_back(cv::Point(boxPts.at<float>(y, 0), boxPts.at<float>(y, 1)));
    }

    vector<cv::Point> sqrPoints = orderPoint(vBoxPts);

    vector<vector<Point> > squares;
    
    for (int y = 0; y < boxPts.rows; y++) {
        cornerPts.push_back((sqrPoints[y] + points[y]) / 2);
    }
    
    squares.push_back(cornerPts); 

    return squares;
    */
   int erosion_size = 5;
    cv::Mat blur, mask;
    cv::Mat element = cv::getStructuringElement(cv::MORPH_CROSS,
        cv::Size(2 * erosion_size + 1, 2 * erosion_size + 1),
        cv::Point(erosion_size, erosion_size));
    vector<vector<cv::Point> > contours;
    vector<cv::Point> found, approx;
    GaussianBlur(image, blur, Size(5, 5), 0, 0, 0);
    cvtColor(blur, blur, COLOR_BGR2HSV);
    inRange(blur, Scalar(21, 39, 64), Scalar(40, 255, 255), mask);
    Canny(mask, mask, 30, 40, 3);
    dilate(mask, mask, element);

    findContours(mask, contours, RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);

    int conteo = 0;
    int iWidth = image.size().width;
    int iHeight = image.size().height;
    int area = iWidth * iHeight;

    for (const auto& contour : contours) {
        if (cv::contourArea(contour) >= area * 0.2 && cv::contourArea(contour) <= area * 0.8) {
            found = contour;
            break;
        }
        conteo++;
    }
    //cout << found;

    float epsilon = 0.1 * arcLength(found, true);
    approxPolyDP(found, approx, epsilon, true);
    cout << approx;

    vector<cv::Point> points = orderPoint(approx);
    cout << points;

    cv::cvtColor(mask, mask, CV_GRAY2BGR);    

    RotatedRect minRect = minAreaRect(found);
    Mat boxPts;
    boxPoints(minRect, boxPts);
    cout << endl << "boxPts " << endl << " " << boxPts << endl;

    vector<Point> vBoxPts, cornerPts;

    for (int y = 0; y < boxPts.rows; y++) {
        vBoxPts.push_back(cv::Point(boxPts.at<float>(y, 0), boxPts.at<float>(y, 1)));
    }

    vector<cv::Point> sqrPoints = orderPoint(vBoxPts);

    vector<vector<Point> > squares;
    
    for (int y = 0; y < boxPts.rows; y++) {
        cornerPts.push_back((sqrPoints[y] + points[y]) / 2);
    }
    
    squares.push_back(cornerPts); 

    return squares;
    
}