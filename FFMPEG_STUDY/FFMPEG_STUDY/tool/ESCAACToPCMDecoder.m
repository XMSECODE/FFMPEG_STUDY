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

typedef struct AACDFFmpeg {
    AVCodecContext *pCodecCtx;
    AVFrame *pFrame;
    struct SwrContext *au_convert_ctx;
    int out_buffer_size;
} AACDFFmpeg;

void *aac_decoder_create(int sample_rate, int channels, int bit_rate) {
    av_register_all();
    AACDFFmpeg *pComponent = (AACDFFmpeg *)malloc(sizeof(AACDFFmpeg));
    AVCodec *pCodec = avcodec_find_decoder(AV_CODEC_ID_AAC);
    if (pCodec == NULL) {
        printf("find aac decoder error\r\n");
        return 0;
    }
    // 创建显示contedxt
    pComponent->pCodecCtx = avcodec_alloc_context3(pCodec);
    pComponent->pCodecCtx->channels = channels;
    pComponent->pCodecCtx->sample_rate = sample_rate;
    pComponent->pCodecCtx->bit_rate = bit_rate;
    if(avcodec_open2(pComponent->pCodecCtx, pCodec, NULL) < 0) {
        printf("open codec error\r\n");
        return 0;
    }
    pComponent->pFrame = av_frame_alloc();
    uint64_t out_channel_layout = channels < 2 ? AV_CH_LAYOUT_MONO:AV_CH_LAYOUT_STEREO;
    int out_nb_samples = 1024;
    enum AVSampleFormat out_sample_fmt = AV_SAMPLE_FMT_S16;

    pComponent->au_convert_ctx = swr_alloc_set_opts(NULL, out_channel_layout, out_sample_fmt, sample_rate, out_channel_layout, AV_SAMPLE_FMT_FLTP, sample_rate, 0, NULL);
    
    int errorcode = swr_init(pComponent->au_convert_ctx);
    if (errorcode != 0) {
        printf("%d",errorcode);
    }
    int out_channels = av_get_channel_layout_nb_channels(out_channel_layout);
    pComponent->out_buffer_size = av_samples_get_buffer_size(NULL, out_channels, out_nb_samples, out_sample_fmt, 1);
    
    
    
    return (void *)pComponent;
}

int aac_decode_frame(void *pParam, unsigned char *pData, int nLen, unsigned char *pPCM, unsigned int *outLen,AVFrame *inputFrame) {
    AACDFFmpeg *pAACD = (AACDFFmpeg *)pParam;
    AVPacket packet;
    av_init_packet(&packet);
    packet.size = nLen;
    packet.data = pData;
    int got_frame = 0;
    
    int result = swr_convert_frame(pAACD->au_convert_ctx, pAACD->pFrame, inputFrame);
    if (result != 0) {
        printf("convert audio frame failed !");
    }
    
//    int nRet = 0;
//    if (packet.size > 0) {
//        nRet = avcodec_send_packet(pAACD->pCodecCtx, &packet);
//        switch (nRet) {
//            case 0:{
//
//                nRet = avcodec_receive_frame(pAACD->pCodecCtx, pAACD->pFrame);
//                //        nRet = avcodec_decode_audio4(pAACD->pCodecCtx, pAACD->pFrame, &got_frame, &packet);
//                switch (nRet) {
//                    case 0:{
//
//
//                    }
//                        break;
//
//                    case AVERROR_EOF:
//                        printf("video the decoder has been fully flushed, and there will be no more output frames.\n");
//                        break;
//
//                    case AVERROR(EAGAIN):
//                        printf("Resource temporarily unavailable\n");
//                        break;
//
//                    case AVERROR(EINVAL):
//                        printf("Invalid argument\n");
//                        break;
//                    default:
//                        break;
//                }
//                if (nRet < 0) {
//                    printf("avcodec_decode_audio4:%d\r\n",nRet);
//                    //            printf("avcodec_decode_audio4 %d sameles = %d outSize = %d\r\n", nRet, pAACD->pFrame->nb_samples, pAACD->out_buffer_size); return nRet; } if(got_frame) { swr_convert(pAACD->au_convert_ctx, &pPCM, pAACD->out_buffer_size, (const uint8_t **)pAACD->pFrame->data, pAACD->pFrame->nb_samples);
//                    //                *outLen = pAACD->out_buffer_size;
//                }
//            }
//                break;
//
//            case AVERROR_EOF:
//                printf("video the decoder has been fully flushed, and there will be no more output frames.\n编码器被flushed，而且没有新的packets被送达到这里。\n");
//                break;
//
//            case AVERROR(EAGAIN):
//                printf("Resource temporarily unavailable\n当前状态不接收输入-用户必须读取avcodec_receive_frame()的输出结果（一旦所有的输出都读取了，这个包将会重新发送，然后就不会发生因为EAGAIN调用失败）。\n");
//                break;
//
//            case AVERROR(EINVAL):
//                printf("Invalid argument\n编解码器没有打开，它是一个编码器，或者需要flush\n");
//
//                break;
//            case AVERROR(ENOMEM):
//                printf("Invalid argument\n添加packet到内部队列失败，或者类似的其他错误：合法的解码错误\n");
//                break;
//            default:
//                break;
//        }
////        if (nRet < 0) {
////            printf("avcodec_decode_audio4:%d\r\n",nRet);
////            //            printf("avcodec_decode_audio4 %d sameles = %d outSize = %d\r\n", nRet, pAACD->pFrame->nb_samples, pAACD->out_buffer_size); return nRet; } if(got_frame) { swr_convert(pAACD->au_convert_ctx, &pPCM, pAACD->out_buffer_size, (const uint8_t **)pAACD->pFrame->data, pAACD->pFrame->nb_samples);
//////            *outLen = pAACD->out_buffer_size;
////            return -1;
////        }
//
//    }
    av_packet_unref(&packet);
//    if (nRet > 0) {
//        return 0;
//    }
    return -1;
}

void aac_decode_close(void *pParam) {
    AACDFFmpeg *pComponent = (AACDFFmpeg *)pParam;
    if (pComponent == NULL) {
        return;
    }
    swr_free(&pComponent->au_convert_ctx);
    if (pComponent->pFrame != NULL) {
        av_frame_free(&pComponent->pFrame);
        pComponent->pFrame = NULL;
    }
    if (pComponent->pCodecCtx != NULL) {
        avcodec_close(pComponent->pCodecCtx);
        avcodec_free_context(&pComponent->pCodecCtx);
        pComponent->pCodecCtx = NULL;
    }
    free(pComponent);
}

@implementation ESCAACToPCMDecoder
+ (AVFrame *)getPCMAVFrameFromOtherFormat:(AVFrame *)frame {
    SwrContext *swrContext = swr_alloc_set_opts(NULL, 1, AV_SAMPLE_FMT_S32, 48000, frame->channel_layout, frame->format, frame->sample_rate, 0, 0);
    if (swrContext == NULL) {
        NSLog(@"create swrcontext failed!");
        return nil;
    }
    AVFrame *RGBFrame = av_frame_alloc();
    RGBFrame->sample_rate = 48000;
    RGBFrame->channel_layout = 1;
    RGBFrame->format = AV_SAMPLE_FMT_S32;
    int result = swr_convert_frame(swrContext, RGBFrame, frame);
    if (result != 0) {
        NSLog(@"convert frame failed!");
        swr_free(&swrContext);
        av_frame_free(&RGBFrame);
        return nil;
    }
    swr_free(&swrContext);

    return RGBFrame;
}
@end
