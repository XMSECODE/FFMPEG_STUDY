//
//  ECSwsscaleManager.m
//  FFMPEG_STUDY
//
//  Created by xiangmingsheng on 2017/6/24.
//  Copyright © 2017年 XMSECODE. All rights reserved.
//

#import "ECSwsscaleManager.h"
#import "swscale.h"
#import "imgutils.h"
#import "Header.h"

@implementation ECSwsscaleManager

+ (UIImage *)getImageFromAVFrame:(AVFrame *)frame {

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

+ (AVFrame *)getRGBAVFrameFromOtherFormat:(AVFrame *)frame {
    struct SwsContext *swsContext = sws_getContext(frame->width, frame->height, AV_PIX_FMT_YUV420P, frame->width, frame->height, AV_PIX_FMT_RGB24, SWS_BICUBIC, NULL, NULL, NULL);
    
    AVFrame *RGBFrame = av_frame_alloc();
    
    int result = av_image_alloc(RGBFrame->data, RGBFrame->linesize, frame->width, frame->height, AV_PIX_FMT_RGB24, 1);
    
    if (result< 0) {
        printf( "Could not allocate destination image\n");
        av_frame_free(&RGBFrame);
        sws_freeContext(swsContext);
        return nil;;
    }
    int result_height = sws_scale(swsContext, (const uint8_t* const*)frame->data, frame->linesize, 0, frame->height, RGBFrame->data, RGBFrame->linesize);
    
    if (result_height == 0) {
        av_free(RGBFrame->data[0]);
        av_frame_free(&RGBFrame);
        sws_freeContext(swsContext);
        return nil;
    }
    RGBFrame->width = frame->width;
    RGBFrame->height = frame->height;
    sws_freeContext(swsContext);
    return RGBFrame;
}

+ (void)saveToPNGImageWithAVFrame:(AVFrame *)frame filePath:(NSString *)filePath success:(void(^)())success failure:(void(^)(NSError *error))failure {
    
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

@end
