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

@interface ESCAACToPCMDecoder()

@property(nonatomic,assign)SwrContext *swrContext;

@property(nonatomic,assign)AVFrame* pcmFrame;

@end

@implementation ESCAACToPCMDecoder

- (void)initConvertWithFrame:(AVFrame *)frame {
    SwrContext *swrContext = swr_alloc_set_opts(NULL, AV_CH_LAYOUT_STEREO, AV_SAMPLE_FMT_S32, 48000, frame->channel_layout, frame->format, frame->sample_rate, 0, 0);
    if (swrContext == NULL) {
        NSLog(@"create swrcontext failed!");
    }else {
        self.swrContext = swrContext;
    }
    AVFrame *PCMFrame = av_frame_alloc();
    PCMFrame->sample_rate = 48000;
    PCMFrame->channel_layout = AV_CH_LAYOUT_STEREO;
    PCMFrame->format = AV_SAMPLE_FMT_S32;
    self.pcmFrame = PCMFrame;
}

- (void)destroy {
    swr_free(&_swrContext);
}

- (void)freeAudioFrame:(AVFrame *)audioFrame {
    av_frame_free(&audioFrame);
}

- (AVFrame *)getPCMAVFrameFromOtherFormat:(AVFrame *)frame {
    int result = swr_convert_frame(self.swrContext, _pcmFrame, frame);
    if (result != 0) {
        NSLog(@"convert frame failed!");
        if (_pcmFrame != NULL) {        
            av_frame_free(&_pcmFrame);
        }
        return nil;
    }
    return _pcmFrame;
}

@end
