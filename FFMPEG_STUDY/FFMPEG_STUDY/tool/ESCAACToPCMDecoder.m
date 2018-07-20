//
//  ESCAACToPCMDecoder.m
//  FFMPEG_STUDY
//
//  Created by xiang on 2018/7/18.
//  Copyright © 2018年 XMSECODE. All rights reserved.
//

#import "ESCAACToPCMDecoder.h"
#include "libavformat/avformat.h"
#include "libswresample/swresample.h"
#include "libavcodec/avcodec.h"


@implementation ESCAACToPCMDecoder
+ (AVFrame *)getPCMAVFrameFromOtherFormat:(AVFrame *)frame {
    SwrContext *swrContext = swr_alloc_set_opts(NULL, AV_CH_LAYOUT_STEREO, AV_SAMPLE_FMT_S32, 48000, frame->channel_layout, frame->format, frame->sample_rate, 0, 0);
    if (swrContext == NULL) {
        NSLog(@"create swrcontext failed!");
        return nil;
    }
    AVFrame *PCMFrame = av_frame_alloc();
    PCMFrame->sample_rate = 48000;
    PCMFrame->channel_layout = AV_CH_LAYOUT_STEREO;
    PCMFrame->format = AV_SAMPLE_FMT_S32;
    int result = swr_convert_frame(swrContext, PCMFrame, frame);
    if (result != 0) {
        NSLog(@"convert frame failed!");
        swr_free(&swrContext);
        av_frame_free(&PCMFrame);
        return nil;
    }
    swr_free(&swrContext);

    return PCMFrame;
}
@end
