
//  ECSwsscaleManager.m
//  FFMPEG_STUDY
//
//  Created by xiangmingsheng on 2017/6/24.
//  Copyright © 2017年 XMSECODE. All rights reserved.
//

#import "ESCSwsscaleTool.h"
#import "swscale.h"
#import "imgutils.h"
#import "Header.h"

@interface ESCSwsscaleTool()

@property(nonatomic,assign)struct SwsContext * swsContext;

@property(nonatomic,assign)enum AVPixelFormat pixelFormat;

@property(nonatomic,assign)int width;

@property(nonatomic,assign)int height;

@end

@implementation ESCSwsscaleTool

- (UIImage *)getImageFromAVFrame:(AVFrame *)frame {

    AVFrame *RGBFrame = [self getRGBAVFrameFromOtherFormat:frame];
    
    NSString *headerString = [NSString stringWithFormat:@"P6\n%d %d\n255\n",frame->width,frame->height];
    NSData *data = [headerString dataUsingEncoding:NSUTF8StringEncoding];
    NSData *bodyData = [NSData dataWithBytes:RGBFrame->data[0] length:frame->width * frame->height * 3];
    NSMutableData *mData = [data mutableCopy];
    [mData appendData:bodyData];
    
    UIImage *image = [UIImage imageWithData:mData];
    
    av_free(RGBFrame->data[0]);
    av_frame_free(&RGBFrame);
    
    return image;
}

- (void)setupWithAVFrame:(AVFrame *)frame outFormat:(ESCPixelFormat)pixelFormat {
    enum AVPixelFormat format;
    if (pixelFormat == ESCPixelFormatRGB) {
        format = AV_PIX_FMT_RGB24;
    }else {
        format = AV_PIX_FMT_YUV420P;
    }
    self.pixelFormat = format;
    struct SwsContext *swsContext = sws_getContext(frame->width, frame->height, frame->format, frame->width, frame->height, format, SWS_BICUBIC, NULL, NULL, NULL);
    self.width = frame->width;
    self.height = frame->height;
    if (swsContext) {
        self.swsContext = swsContext;
    }
}

- (AVFrame *)getAVFrame:(AVFrame *)inFrame {
    AVFrame *resultFrame = av_frame_alloc();
    
    int result = av_image_alloc(resultFrame->data, resultFrame->linesize, self.width, self.height, self.pixelFormat, 1);
    
    if (result< 0) {
        printf( "Could not allocate destination image\n");
        av_frame_free(&resultFrame);
        return nil;;
    }
    int result_height = sws_scale(self.swsContext, (const uint8_t* const*)inFrame->data, inFrame->linesize, 0, inFrame->height, resultFrame->data, resultFrame->linesize);
    
    if (result_height == 0) {
        av_free(resultFrame->data[0]);
        av_frame_free(&resultFrame);
        return nil;
    }
    resultFrame->width = self.width;
    resultFrame->height = self.height;
    return resultFrame;
}

- (AVFrame *)getRGBAVFrameFromOtherFormat:(AVFrame *)frame {
    
    AVFrame *RGBFrame = av_frame_alloc();
    
    int result = av_image_alloc(RGBFrame->data, RGBFrame->linesize, frame->width, frame->height, AV_PIX_FMT_RGB24, 1);
    
    if (result< 0) {
        printf( "Could not allocate destination image\n");
        av_frame_free(&RGBFrame);
        return nil;;
    }
    int result_height = sws_scale(self.swsContext, (const uint8_t* const*)frame->data, frame->linesize, 0, frame->height, RGBFrame->data, RGBFrame->linesize);
    
    if (result_height == 0) {
        av_free(RGBFrame->data[0]);
        av_frame_free(&RGBFrame);
        return nil;
    }
    RGBFrame->width = frame->width;
    RGBFrame->height = frame->height;
    return RGBFrame;
}

- (void)saveToPNGImageWithAVFrame:(AVFrame *)frame filePath:(NSString *)filePath success:(void(^)())success failure:(void(^)(NSError *error))failure {
    
    UIImage *image = [self getImageFromAVFrame:frame];
    NSData *imageData = UIImagePNGRepresentation(image);
    BOOL isSuccess = [imageData writeToFile:filePath atomically:YES];
    if (isSuccess) {
        success();
    }else {
        NSError *error = [NSError EC_errorWithLocalizedDescription:@"write to file failuer"];
        failure(error);
    }
}

- (void)destroy {
    sws_freeContext(self.swsContext);
}

@end
