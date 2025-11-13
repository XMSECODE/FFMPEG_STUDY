//
//  ESCffmpegRecorder.m
//  CloudViews
//
//  Created by xiang on 2018/8/9.
//  Copyright © 2018年 mac. All rights reserved.
//

#import "ESCffmpegRecorder.h"
#import <libavutil/avassert.h>
#import <libavutil/channel_layout.h>
#import <libavutil/opt.h>
#import <libavutil/mathematics.h>
#import <libavutil/timestamp.h>
#import <libavformat/avformat.h>
#import <libavcodec/avcodec.h>
#import <libswscale/swscale.h>
#import <libswresample/swresample.h>

#define MAX_NALUS_SIZE (5000)

@interface ESCffmpegRecorder ()
@property(nonatomic,assign) AVFormatContext *formatContext;
@property(nonatomic,assign) AVStream *o_video_stream;
@property(nonatomic,assign) uint8_t  *strH264Nalu;
@property(nonatomic,assign) int iH264NaluSize;
@property(nonatomic,assign) int64_t v_pts;
@property(nonatomic,assign) int64_t v_dts;
// 保持CodecContext（用于extradata管理，写帧等），需后续free
@property(nonatomic,assign) AVCodecContext *videoCodecContext;
@end

@implementation ESCffmpegRecorder

+ (instancetype)recordFileWithFilePath:(NSString *)filePath
                             codecType:(NSInteger)codecType
                            videoWidth:(NSInteger)videoWidth
                           videoHeight:(NSInteger)videoHeight
                        videoFrameRate:(NSInteger)videoFrameRate
{
    ESCffmpegRecorder *record = [[ESCffmpegRecorder alloc] init];
    // 分配H264 nalu缓存
    record.strH264Nalu = av_malloc(MAX_NALUS_SIZE);

    AVFormatContext *formatContext = NULL;
    const char *fileCharPath = [filePath cStringUsingEncoding:NSUTF8StringEncoding];
    int ret = avformat_alloc_output_context2(&formatContext, NULL, NULL, fileCharPath);
    if (!formatContext || ret < 0) {
        printf("formatContext alloc failed!\n");
        return nil;
    }
    // 明确视频编码类型
    formatContext->video_codec_id = (int)codecType;

    AVStream *videoStream = avformat_new_stream(formatContext, NULL);
    if (!videoStream) {
        printf("alloc video stream failed!\n");
        avformat_free_context(formatContext);
        return nil;
    }

    // 选择编码器
    const AVCodec *codec = avcodec_find_encoder(codecType);
    if (!codec) {
        printf("encoder not found!\n");
        avformat_free_context(formatContext);
        return nil;
    }

    AVCodecContext *codecContext = avcodec_alloc_context3(codec);
    if (!codecContext) {
        printf("codec alloc failed!\n");
        avformat_free_context(formatContext);
        return nil;
    }

    // 视频参数设置
    codecContext->codec_type = AVMEDIA_TYPE_VIDEO;
    codecContext->codec_id = codecType;
    codecContext->bit_rate = 800000;
    codecContext->width = videoWidth;
    codecContext->height = videoHeight;
    codecContext->time_base = (AVRational){ 1, (int)videoFrameRate };
    codecContext->framerate = (AVRational){ (int)videoFrameRate, 1 };
    codecContext->gop_size = 12; // 可选
    codecContext->pix_fmt = AV_PIX_FMT_YUV420P;
    codecContext->flags = 0;
    if (formatContext->oformat->flags & AVFMT_GLOBALHEADER) {
        codecContext->flags |= AV_CODEC_FLAG_GLOBAL_HEADER;
    }
    
    // 打开编码器
    ret = avcodec_open2(codecContext, codec, NULL);
    if (ret < 0) {
        printf("open encoder failed!\n");
        avcodec_free_context(&codecContext);
        avformat_free_context(formatContext);
        return nil;
    }

    // 从 codecContext 拷贝参数到 stream->codecpar
    ret = avcodec_parameters_from_context(videoStream->codecpar, codecContext);
    if (ret < 0) {
        printf("copy codecpar failed!\n");
        avcodec_free_context(&codecContext);
        avformat_free_context(formatContext);
        return nil;
    }

    // 时间基一一致
    videoStream->time_base = codecContext->time_base;

    // 打开输出
    av_dump_format(formatContext, 0, fileCharPath, 1);
    ret = avio_open(&formatContext->pb, fileCharPath, AVIO_FLAG_WRITE);
    if (ret < 0) {
        printf("open io failed!\n");
        avcodec_free_context(&codecContext);
        avformat_free_context(formatContext);
        return nil;
    }

    ret = avformat_write_header(formatContext, NULL);
    if (ret < 0) {
        printf("write header failed!\n");
        avcodec_free_context(&codecContext);
        avio_close(formatContext->pb);
        avformat_free_context(formatContext);
        return nil;
    }

    record.formatContext = formatContext;
    record.o_video_stream = videoStream;
    record.videoCodecContext = codecContext;
    record.v_pts = 0;
    record.v_dts = 0;
    record.iH264NaluSize = 0;
    return record;
}

- (void)writeVideoFrame:(void *)data length:(NSInteger)length {
    if (!self.formatContext || !self.o_video_stream || !self.videoCodecContext) return;
    uint8_t *pData = (uint8_t *)data;
    int iLen = (int)length;
    AVPacket pkt;
    av_init_packet(&pkt);
    pkt.size = iLen;
    pkt.data = pData;
    pkt.stream_index = self.o_video_stream->index;

    // Demo: 临时extradata设置（此写法实际场景应提前整理extradata再set）
    if (iLen > 4 && pData[0] == 0x0 && pData[1] == 0x0 && pData[2] == 0x0 && pData[3] == 0x1) {
        // 仅举例：H264/H265的SPS/PPS/NALU提取
        if ((self.videoCodecContext->codec_id == AV_CODEC_ID_H264 && (pData[4] & 0x0f) == (0x67 & 0x0f))
            || (self.videoCodecContext->codec_id == AV_CODEC_ID_HEVC && pData[4] == 0x40)) {
            // 这里通常只放sps/pps，如果没有请跳过，否则写header可能无效
            int nalus_num = 0;
            for (int num = 0; num < iLen; num++) {
                // 简单例子，实际需完整NALU查找
                if (pData[num] == 0x68 || pData[num] == 0x90) {
                    nalus_num = num;
                    break;
                }
            }
            if (nalus_num > 0 && nalus_num < MAX_NALUS_SIZE) {
                memcpy(self.strH264Nalu, pData, nalus_num);
                self.iH264NaluSize = nalus_num;
                // 更新extradata
                av_freep(&self.videoCodecContext->extradata);
                self.videoCodecContext->extradata = av_malloc(self.iH264NaluSize + AV_INPUT_BUFFER_PADDING_SIZE);
                memcpy(self.videoCodecContext->extradata, self.strH264Nalu, self.iH264NaluSize);
                self.videoCodecContext->extradata_size = self.iH264NaluSize;
                avcodec_parameters_from_context(self.o_video_stream->codecpar, self.videoCodecContext);
            }
            pkt.flags |= AV_PKT_FLAG_KEY;
        }
    }

    pkt.dts = self.v_dts;
    pkt.pts = self.v_pts;

    // write frame
    av_packet_rescale_ts(&pkt, self.videoCodecContext->time_base, self.o_video_stream->time_base);
    int ret = av_interleaved_write_frame(self.formatContext, &pkt);
    if (ret < 0) {
        printf("write frame failed! %d\n", ret);
    }

    self.v_dts++;
    self.v_pts++;
    // 注意：pkt并未由编码器分配，不需unref!!!
}

- (void)stopRecord {
    if (self.formatContext) {
        av_write_trailer(self.formatContext);

        if (self.videoCodecContext) {
            avcodec_free_context(&_videoCodecContext);
        }
        if (self.formatContext->pb) {
            avio_close(self.formatContext->pb);
        }
        avformat_free_context(self.formatContext);
        self.formatContext = NULL;
        self.o_video_stream = NULL;
    }
    if (self.strH264Nalu) {
        av_freep(&_strH264Nalu);
        self.strH264Nalu = NULL;
    }
}

@end
