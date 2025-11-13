//
//  FFmpegRemuxer.m
//  FFMPEG_STUDY
//
//  Created by xiang on 16/08/2017.
//  Copyright © 2017 XMSECODE. All rights reserved.
//

#import "FFmpegRemuxer.h"
#import "avformat.h"
#import "avcodec.h"
#import <AVFoundation/AVFoundation.h>

@interface FFmpegRemuxer () {
    AVFormatContext *pInFormatContext;  //数据文件操作者,用于存储音视频封装格式中包含的信息。解封装格式的结构体
    AVFormatContext *pOutFormatContext;
    AVOutputFormat *outputFormat;       //输出的格式,包括音频封装格式,视频封装格式,字幕封装格式,所有封装格式都在AVCodecID这个枚举类型上面
    AVPacket pPacket;                   //创建编码后的数据AVPacket来存储AVFrame编码后生成的数据
    
    const char *in_filename;
    const char *out_filename;
}

@end

@implementation FFmpegRemuxer

- (void)initBasicInfo:(NSString *)filePath {
    in_filename = [filePath cStringUsingEncoding:NSUTF8StringEncoding];
    NSString *outFileNameString = [NSTemporaryDirectory() stringByAppendingPathComponent:@"mov2flv.flv"];
    out_filename = [outFileNameString cStringUsingEncoding:NSUTF8StringEncoding];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outFileNameString]) {
        [[NSFileManager defaultManager] removeItemAtPath:outFileNameString error:nil];
    }
}

- (void)moToFlv:(NSString *)filePath {
    [self initBasicInfo:filePath];
    
    int errorCode;
    
    //2.1avformat_open_input
    errorCode = avformat_open_input(&pInFormatContext, in_filename, 0, NULL);
    if (errorCode != 0) {
        printf("Could not open input file!");
        [self endEncode];
        return;
    }
    
    //2.2.avformat_find_stream_info
    errorCode = avformat_find_stream_info(pInFormatContext, NULL);
    if (errorCode != 0) {
        printf("failed to retrieve input stream information!");
        [self endEncode];
        return;
    }
    av_dump_format(pInFormatContext, 0, in_filename, 0);
    
    //3.初始化输出码流的AVFormatContext
    errorCode = avformat_alloc_output_context2(&pOutFormatContext, NULL, NULL, out_filename);
    if (errorCode != 0) {
        printf("failed avformat_alloc_output_context2");
        [self endEncode];
        return;
    }
    outputFormat = pOutFormatContext->oformat;
    
    //4.遍历inputFormatContext的stream，复制到pCodeContext中
    for (int i = 0; i < pInFormatContext->nb_streams; i++) {
        AVStream *in_stream = pInFormatContext->streams[i];
        //4.1查找编码器
        AVCodec *codec = avcodec_find_decoder(in_stream->codecpar->codec_id);
        //4.2创建输出码流的AVStream
        AVStream *out_stream = avformat_new_stream(pOutFormatContext, codec);
        if (!out_stream) {
            printf("failed allocting out stream!");
            [self endEncode];
            return;
        }
        //4.3为输出文件设置编码所需的参数和格式，一个AVStream对应一个AVCodecContext
        AVCodecContext *pOutCodeContext = avcodec_alloc_context3(codec);
        errorCode = avcodec_parameters_to_context(pOutCodeContext, in_stream->codecpar);
        if (errorCode < 0) {
            printf("failed to copy context input to output stream codec context！");
            [self endEncode];
            return;
        }
        
        pOutCodeContext->codec_tag = 0;
        if (pOutFormatContext->oformat->flags & AVFMT_GLOBALHEADER) {
            pOutCodeContext->flags |= AV_CODEC_FLAG_GLOBAL_HEADER;
        }
        
        errorCode = avcodec_parameters_from_context(out_stream->codecpar, pOutCodeContext);
        if (errorCode < 0) {
            printf("failed to copy  context input to output stream codec context!");
            [self endEncode];
            return;
        }
    }
    
    
    av_dump_format(pOutFormatContext, 0, out_filename, 1);
    
    //5.avio_open 打开输出端文件，将输出文件中的数据读入到程序的buffer中
    if (!(outputFormat->flags & AVFMT_NOFILE)) {
        errorCode = avio_open(&pOutFormatContext->pb, out_filename, AVIO_FLAG_WRITE);
        if (errorCode < 0) {
            printf("Could not open output file %s",out_filename);
            [self endEncode];
            return;
        }
    }
    
    //6.avformat_writ_header
    errorCode = avformat_write_header(pOutFormatContext, NULL);
    if (errorCode < 0) {
        printf("error occurred when opening output file\n");
        [self endEncode];
        return;
    }
    
    //7.av_interleaved_write_frame
    int frame_index = 0;
    while (1) {
        AVStream *in_stream,*out_stream;
        //7.1av_read_frame get a packet 从输入文件中读取一个packet
        errorCode = av_read_frame(pInFormatContext, &pPacket);
        if (errorCode < 0) {
            printf("erroe av_read_frame");
            break;
        }
        
        in_stream = pInFormatContext->streams[pPacket.stream_index];
        out_stream = pOutFormatContext->streams[pPacket.stream_index];
        //7.2copy packet convert PTS/DTS
        pPacket.pts = av_rescale_q_rnd(pPacket.pts, in_stream->time_base, out_stream->time_base, AV_ROUND_NEAR_INF | AV_ROUND_PASS_MINMAX);
        pPacket.dts = av_rescale_q_rnd(pPacket.dts, in_stream->time_base, out_stream->time_base, AV_ROUND_NEAR_INF | AV_ROUND_PASS_MINMAX);
        pPacket.duration = av_rescale_q(pPacket.duration, in_stream->time_base, out_stream->time_base);
        pPacket.pos = -1;
        //7.3
        errorCode = av_interleaved_write_frame(pOutFormatContext, &pPacket);
        if (errorCode < 0) {
            printf("error muxing packet\n");
            break;
        }
        printf("write %8d frames to output file\n",frame_index);
        av_packet_unref(&pPacket);
        frame_index++;
    }
    
    av_write_trailer(pOutFormatContext);
    [self endEncode];
    
}

- (void)endEncode {
    int errorCode = 0;
    avformat_close_input(&pInFormatContext);
    if (pOutFormatContext && !(pOutFormatContext->flags & AVFMT_NOFILE)) {
        errorCode = avio_close(pOutFormatContext->pb);
    }
    avformat_free_context(pOutFormatContext);
    if (errorCode < 0 && errorCode != AVERROR_EOF) {
        printf("Error occured.\n");
        return;
    }
}

@end
