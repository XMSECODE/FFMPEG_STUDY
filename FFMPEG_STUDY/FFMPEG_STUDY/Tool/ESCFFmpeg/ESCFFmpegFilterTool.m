//
//  ESCFFmpegFilterTool.m
//  FFMPEG_STUDY
//
//  Created by xiang on 2019/4/10.
//  Copyright © 2019 XMSECODE. All rights reserved.
//

#import "ESCFFmpegFilterTool.h"
#import "avfilter.h"
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavfilter/avfiltergraph.h>
#include <libavfilter/buffersink.h>
#include <libavfilter/buffersrc.h>
#include <libavutil/opt.h>

typedef struct Filter_Args
{
    int width;
    int height;
    enum AVPixelFormat pix_fmt;
    AVRational time_base;
    AVRational sample_aspect_ratio;
}FilterArgs;

@interface ESCFFmpegFilterTool ()

@property(nonatomic,assign)AVFilter filter;

@property(nonatomic,assign)BOOL initSuccess;

@property(nonatomic,assign)AVFilterContext *buffersink_ctx;

@property(nonatomic,assign)AVFilterContext *buffersrc_ctx;

@property(nonatomic,assign)AVFilterGraph *filter_graph;

@end

@implementation ESCFFmpegFilterTool

-(int)init_filtersWithFilters_descr:(char *)filters_descr filterArgs:(FilterArgs *)filter_args {
    char args[512];
    int ret = 0;
    AVFilter *buffersrc  = avfilter_get_by_name("buffer");
    AVFilter *buffersink = avfilter_get_by_name("buffersink");
    
    enum AVPixelFormat pix_fmts[] = { AV_PIX_FMT_YUV420P, AV_PIX_FMT_NONE };
    
    AVFilterInOut *outputs = avfilter_inout_alloc();
    AVFilterInOut *inputs  = avfilter_inout_alloc();
    _filter_graph = avfilter_graph_alloc();
    if (!outputs || !inputs || !_filter_graph) {
        ret = AVERROR(ENOMEM);
        goto end;
    }
    
    /* buffer video source: the decoded frames from the decoder will be inserted here. */
    snprintf(args, sizeof(args),"video_size=%dx%d:pix_fmt=%d:time_base=%d/%d:pixel_aspect=%d/%d",filter_args->width, filter_args->height, filter_args->pix_fmt,filter_args->time_base.num, filter_args->time_base.den,filter_args->sample_aspect_ratio.num, filter_args->sample_aspect_ratio.den);

    ret = avfilter_graph_create_filter(&_buffersrc_ctx, buffersrc, "in",
                                       args, NULL, _filter_graph);
    if (ret < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot create buffer source\n");
        goto end;
    }
    
    /* buffer video sink: to terminate the filter chain. */
    ret = avfilter_graph_create_filter(&_buffersink_ctx, buffersink, "out",
                                       NULL, NULL, _filter_graph);
    if (ret < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot create buffer sink\n");
        goto end;
    }
    
    ret = av_opt_set_int_list(_buffersink_ctx, "pix_fmts", pix_fmts,
                              AV_PIX_FMT_NONE, AV_OPT_SEARCH_CHILDREN);
    if (ret < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot set output pixel format\n");
        goto end;
    }
    
    /*
     * Set the endpoints for the filter graph. The filter_graph will
     * be linked to the graph described by filters_descr.
     */
    
    /*
     * The buffer source output must be connected to the input pad of
     * the first filter described by filters_descr; since the first
     * filter input label is not specified, it is set to "in" by
     * default.
     */
    outputs->name       = av_strdup("in");
    outputs->filter_ctx = _buffersrc_ctx;
    outputs->pad_idx    = 0;
    outputs->next       = NULL;
    
    /*
     * The buffer sink input must be connected to the output pad of
     * the last filter described by filters_descr; since the last
     * filter output label is not specified, it is set to "out" by
     * default.
     */
    inputs->name       = av_strdup("out");
    inputs->filter_ctx = _buffersink_ctx;
    inputs->pad_idx    = 0;
    inputs->next       = NULL;
    
    if ((ret = avfilter_graph_parse_ptr(_filter_graph, filters_descr,
                                        &inputs, &outputs, NULL)) < 0)
        goto end;
    
    if ((ret = avfilter_graph_config(_filter_graph, NULL)) < 0)
        goto end;
    
end:
    avfilter_inout_free(&inputs);
    avfilter_inout_free(&outputs);
    
    return ret;
}


- (void)setup {
    avfilter_register_all();
}

- (BOOL)setupWithWidth:(int)width
                height:(int)height
           pixelFormat:(enum AVPixelFormat)pixelFormat
             time_base:(AVRational)time_base
   sample_aspect_ratio:(AVRational)sample_aspect_ratio
          filter_descr:(NSString *)filter_descr{
    avfilter_register_all();

    FilterArgs filterargs;
    filterargs.width = width;
    filterargs.height = height;
    filterargs.pix_fmt = pixelFormat;
//    AVRational rational;
    //        rational.num = 1;
    //        rational.den = 1000;
    filterargs.time_base = time_base;
    filterargs.sample_aspect_ratio = sample_aspect_ratio;
    
    char *filter_descr_c = [filter_descr cStringUsingEncoding:NSUTF8StringEncoding];
    int result = [self init_filtersWithFilters_descr:filter_descr_c filterArgs:&filterargs];
    
    
    if (result == 0) {
        self.initSuccess = YES;
        return YES;
    }else {
        self.initSuccess = NO;
        NSLog(@"滤镜初始化失败");
        return NO;
    }
}

- (AVFrame *)filterFrame:(AVFrame *)frame {
    if (self.initSuccess == NO) {
        NSLog(@"滤镜初始化失败");
        return nil;
    }
    frame->pts = frame->best_effort_timestamp;
    AVFrame *filt_frame = av_frame_alloc();
    /* push the decoded frame into the filtergraph */
    if (av_buffersrc_add_frame_flags(_buffersrc_ctx, frame, AV_BUFFERSRC_FLAG_KEEP_REF) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Error while feeding the filtergraph\n");
        NSLog(@"frame添加到滤镜失败");
        av_frame_free(&filt_frame);
        return nil;
    }
    int ret = 0;
    /* pull filtered frames from the filtergraph */
    ret = av_buffersink_get_frame(_buffersink_ctx, filt_frame);
    if (ret == 0) {
        return filt_frame;
    }
    if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF) {
        NSLog(@"no frames are available");
        av_frame_free(&filt_frame);
        return nil;
    }
    if (ret < 0) {
        NSLog(@"获取图像失败");
        av_frame_free(&filt_frame);
        return nil;
    }
    return filt_frame;
}

- (void)destroy {
    avfilter_free(_buffersrc_ctx);
    avfilter_free(_buffersink_ctx);
    avfilter_graph_free(&_filter_graph);
}

@end
