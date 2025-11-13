//
//  ESCAACToPCMDecoder.m
//  FFMPEG_STUDY
//
//  Created by xiang on 2018/7/18.
//  Copyright © 2018年 XMSECODE. All rights reserved.
//

#import "ESCPCMRedecoder.h"
#include "libavformat/avformat.h"
#include "libswresample/swresample.h"
#include "libavcodec/avcodec.h"

@interface ESCPCMRedecoder()

@property(nonatomic,assign)SwrContext *swrContext;

@property(nonatomic,assign)AVFrame* pcmFrame;

@end

@implementation ESCPCMRedecoder

- (void)initConvertWithFrame:(AVFrame *)frame {
    // 设置输出声道布局
    AVChannelLayout out_ch_layout;
    av_channel_layout_default(&out_ch_layout, 2); // 2 = 立体声STEREO

    // SwrContext推荐新形式
    SwrContext *swrContext = NULL;

    int ret = swr_alloc_set_opts2(&swrContext,
                                  &out_ch_layout, AV_SAMPLE_FMT_S32, 48000,        // 输出
                                  &frame->ch_layout, frame->format, frame->sample_rate, // 输入
                                  0, NULL);
    
    if (ret < 0 || !swrContext) {
        NSLog(@"create swrcontext failed!");
    } else {
        self.swrContext = swrContext;
    }

    AVFrame *PCMFrame = av_frame_alloc();
    PCMFrame->sample_rate = 48000;
    av_channel_layout_copy(&PCMFrame->ch_layout, &out_ch_layout); // 新版API替代channel_layout
    PCMFrame->format = AV_SAMPLE_FMT_S32;
    self.pcmFrame = PCMFrame;

    av_channel_layout_uninit(&out_ch_layout); // 用完layout需释放
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
