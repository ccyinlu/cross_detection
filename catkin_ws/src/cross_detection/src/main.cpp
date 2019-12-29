#include <opencv2/opencv.hpp>

#include <ros/ros.h>
#include <image_transport/image_transport.h>
#include <cv_bridge/cv_bridge.h>
#include <sensor_msgs/image_encodings.h>

#include "bboxes_ros_msgs/BoundingBoxes.h"
#include "bboxes_ros_msgs/BoundingBox.h"

using namespace std;

cv::Mat crossTemplate;
cv::Mat crossTemplateH;
int crossTemplateWidth;
int crossTemplateHeight;

int crop_x1 = 0;
int crop_y1 = 0;
int crop_x2 = 0;
int crop_y2 = 0;

int if_render_results = 0;
float h_threshold = 0;
float score_threshold = 0;
ros::Publisher render_image_pub_;
std::string boundingBoxesFrameId = "/crossBoundingBoxes";

ros::Publisher boundingBoxesPublisher_;

void onImageCallback(const sensor_msgs::Image::ConstPtr &msg)
{
    static int counter = 0;
    ROS_INFO("onImageCallback has been triggered ");
    cv_bridge::CvImagePtr cv_ptr;
    try
    {
        cv_ptr = cv_bridge::toCvCopy(msg, sensor_msgs::image_encodings::BGR8);
    }
    catch (cv_bridge::Exception &e)
    {
        ROS_ERROR("cv_bridge exception: %s", e.what());
        return;
    }

    cv::Mat imgRaw = cv_ptr->image;
    // crop the image
    cv::Rect roi;
    roi.x = crop_x1;
    roi.y = crop_y1;
    roi.width = crop_x2 - crop_x1;
    roi.height = crop_y2 - crop_y1;
    cv::Mat img = imgRaw(roi); 

    cv::Mat imgHSV, imgH;
    // convert the image to hsv
    cvtColor(img, imgHSV, cv::COLOR_BGR2HSV);
    std::vector<cv::Mat> imgChannels;
    cv::split(imgHSV, imgChannels);
    imgH = imgChannels[0];
    imgH.convertTo(imgH, CV_32F);
    cv::threshold(1- imgH/255, imgH, h_threshold, 1.0, cv::THRESH_TOZERO);

    cv::Mat Hfiltered;
    cv::filter2D(imgH, Hfiltered, imgH.depth(), crossTemplateH);

    // find the max value and the index of the maxVal
    int maxId[2];
    double score;
    cv::minMaxIdx(Hfiltered, 0, &score, 0, maxId);
    score = std::min(score/255, 1.0);
    ROS_INFO("score: %f, center: [%d,%d]",score, maxId[1], maxId[0]);

    bboxes_ros_msgs::BoundingBoxes m_current_BoundingBoxes;

    m_current_BoundingBoxes.header.stamp = ros::Time::now();
    m_current_BoundingBoxes.header.seq = counter++;
    m_current_BoundingBoxes.header.frame_id = boundingBoxesFrameId;
    m_current_BoundingBoxes.bounding_boxes.clear();

    bboxes_ros_msgs::BoundingBox m_BoundingBox;

    m_BoundingBox.Class = "cross";
    m_BoundingBox.probability = score;
    m_BoundingBox.xmin = std::min(std::max(maxId[1] + crop_x1 - crossTemplateWidth/2, 0), imgRaw.cols);
    m_BoundingBox.ymin = std::min(std::max(maxId[0] + crop_y1 - crossTemplateHeight/2, 0), imgRaw.rows);
    m_BoundingBox.xmax = std::min(std::max(maxId[1] + crop_x1 + crossTemplateWidth/2, 0), imgRaw.cols);
    m_BoundingBox.ymax = std::min(std::max(maxId[0] + crop_y1 + crossTemplateHeight/2, 0), imgRaw.rows);

    if(m_BoundingBox.probability > score_threshold){
        m_current_BoundingBoxes.bounding_boxes.push_back(m_BoundingBox);
    }
    
    boundingBoxesPublisher_.publish(m_current_BoundingBoxes);

    if(if_render_results){
        // draw the point on the image
        cv::rectangle(imgRaw, 
                        cv::Point(crop_x1, crop_y1), 
                        cv::Point(crop_x2, crop_y2), 
                        cv::Scalar(255,0,0), 
                        2, 
                        4, 
                        0);
        for(int i = 0; i < m_current_BoundingBoxes.bounding_boxes.size(); i++){
            cv::rectangle(imgRaw, 
                        cv::Point(m_current_BoundingBoxes.bounding_boxes[i].xmin, m_current_BoundingBoxes.bounding_boxes[i].ymin), 
                        cv::Point(m_current_BoundingBoxes.bounding_boxes[i].xmax, m_current_BoundingBoxes.bounding_boxes[i].ymax), 
                        cv::Scalar(0,0,255), 
                        4, 
                        8, 
                        0);
        char render_txt[1024];
        sprintf(render_txt, "%.2f", m_current_BoundingBoxes.bounding_boxes[i].probability);
        cv::putText(imgRaw, 
                            render_txt, 
                            cv::Point(m_current_BoundingBoxes.bounding_boxes[i].xmin, m_current_BoundingBoxes.bounding_boxes[i].ymin), 
                            cv::FONT_HERSHEY_PLAIN, 
                            4, 
                            cv::Scalar(0,0,255), 
                            4, 
                            8, 
                            0);
        }

        // cv::normalize(Hfiltered, Hfiltered, 255, 0, cv::NORM_MINMAX);
        // Hfiltered.convertTo(Hfiltered, CV_8U);

        // cv::normalize(crossTemplateH, crossTemplateH, 255, 0, cv::NORM_MINMAX);
        // crossTemplateH.convertTo(crossTemplateH, CV_8U);

        // cv::normalize(imgH, imgH, 255, 0, cv::NORM_MINMAX);
        // imgH.convertTo(imgH, CV_8U);

        cv_bridge::CvImage cv_image;
        cv_image.image = imgRaw;
        cv_image.encoding = "bgr8";
        // cv_image.encoding = "mono8";
        sensor_msgs::Image ros_image;
        cv_image.toImageMsg(ros_image);
        render_image_pub_.publish(ros_image);
    }
}

int main(int argc, char *argv[])
{
    // declear ros
    ros::init(argc, argv, "cross_detection");
    ros::NodeHandle nh_;
    ros::NodeHandle nh_privat("~");

    std::string image_raw_topic = "/cam_front/csi_cam/image_raw";
    std::string image_render_topic = "/cam_front/csi_cam/image_raw_render";
    std::string boundingBoxesTopic = "/crossBoundingBoxes";
    
    std::string cross_template_file = "";

    nh_privat.getParam("image_raw_topic", image_raw_topic);
    nh_privat.getParam("image_render_topic", image_render_topic);
    nh_privat.getParam("boundingBoxesTopic", boundingBoxesTopic);
    nh_privat.getParam("boundingBoxesFrameId", boundingBoxesTopic);
    nh_privat.getParam("cross_template_file", cross_template_file);
    nh_privat.getParam("h_threshold", h_threshold);
    nh_privat.getParam("score_threshold", score_threshold);
    nh_privat.getParam("if_render_results", if_render_results);

    nh_privat.getParam("crop_x1", crop_x1);
    nh_privat.getParam("crop_y1", crop_y1);
    nh_privat.getParam("crop_x2", crop_x2);
    nh_privat.getParam("crop_y2", crop_y2);

    ROS_INFO("image_raw_topic: %s", image_raw_topic.c_str());
    ROS_INFO("image_render_topic: %s", image_render_topic.c_str());
    ROS_INFO("boundingBoxesTopic: %s", boundingBoxesTopic.c_str());
    ROS_INFO("boundingBoxesFrameId: %s", boundingBoxesFrameId.c_str());
    ROS_INFO("cross_template_file: %s", cross_template_file.c_str());
    ROS_INFO("h_threshold: %f", h_threshold);
    ROS_INFO("score_threshold: %f", score_threshold);
    ROS_INFO("if_render_results: %d", if_render_results);

    ROS_INFO("crop_x1: %d", crop_x1);
    ROS_INFO("crop_y1: %d", crop_y1);
    ROS_INFO("crop_x2: %d", crop_x2);
    ROS_INFO("crop_y2: %d", crop_y2);

    if(if_render_results){
        render_image_pub_ = nh_.advertise<sensor_msgs::Image>(image_render_topic, 1);
    }

    boundingBoxesPublisher_ = nh_.advertise<bboxes_ros_msgs::BoundingBoxes>(boundingBoxesTopic, 1);

    ros::Subscriber image_sub_;
    image_sub_ = nh_.subscribe(image_raw_topic, 1, onImageCallback);

    if (cross_template_file.length() > 0){
        // read the cross template image file
        crossTemplate = cv::imread(cross_template_file, CV_LOAD_IMAGE_UNCHANGED);
        if(crossTemplate.empty()){
            ROS_ERROR("can not load the cross template");
            return -1;
        }else{
            crossTemplateWidth = crossTemplate.cols;
            crossTemplateHeight = crossTemplate.rows;

            // get the h component from the hsv format
            cv::Mat crossTemplateHSV;
		    cvtColor(crossTemplate, crossTemplateHSV, cv::COLOR_BGR2HSV);
            std::vector<cv::Mat> crossTemplateChannels;
            cv::split(crossTemplateHSV, crossTemplateChannels);
            crossTemplateH = crossTemplateChannels[0];
            crossTemplateH.convertTo(crossTemplateH, CV_32F);
            cv::threshold(1 - crossTemplateH/255, crossTemplateH, h_threshold, 1.0, cv::THRESH_TOZERO);
        }
    }
    else{
        ROS_ERROR("specified cross template image file empty");
        return -1;
    }

    ros::spin();

    return 0;
}
