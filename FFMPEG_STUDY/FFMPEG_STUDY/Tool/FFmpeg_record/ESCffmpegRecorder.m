//
//  ESCffmpegRecorder
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
#import <libswscale/swscale.h>
#import <libswresample/swresample.h>

#define MAX_NALUS_SZIE (5000)


@interface ESCffmpegRecorder ()

@property(nonatomic,assign)AVFormatContext *formatContext;

@property(nonatomic,assign)    AVStream * o_video_stream;

@property(nonatomic,assign)char *strH264Nalu;

@property(nonatomic,assign)int iH264NaluSize;

@property(nonatomic,assign)int64_t v_pts;

@property(nonatomic,assign)int64_t v_dts;

@property(nonatomic,assign)int64_t a_pts;

@property(nonatomic,assign)int64_t a_dts;

@end

@implementation ESCffmpegRecorder

+ (instancetype)recordFileWithFilePath:(NSString *)filePath
                             codecType:(NSInteger)codecType
                            videoWidth:(NSInteger)videoWidth
                           videoHeight:(NSInteger)videoHeight
                        videoFrameRate:(NSInteger)videoFrameRate {
    ESCffmpegRecorder *record = [[ESCffmpegRecorder alloc] init];
    char strh264nalu[MAX_NALUS_SZIE] = {0};
    record.strH264Nalu = strh264nalu;
    av_register_all();
    avcodec_register_all();
    
    AVFormatContext *formatContext;
    const char *fileCharPath = [filePath cStringUsingEncoding:NSUTF8StringEncoding];
    NSInteger ret = avformat_alloc_output_context2(&formatContext, NULL, NULL, fileCharPath);
    if (formatContext == nil) {
        printf("formatContext alloc failed!");
        return nil;
    }
        formatContext->video_codec_id = AV_CODEC_ID_H265;
        if (ret < 0) {
            printf("alloc failed!");
            return nil;
        }
        if (!formatContext)
        {
            printf("Could not deduce output format from file extension\n");
            return nil;
        }
        
        AVStream *o_video_stream;
        o_video_stream = avformat_new_stream(formatContext, NULL);
        AVCodecContext *c;
        c = o_video_stream->codec;
        
        o_video_stream->time_base = (AVRational){ 1, videoFrameRate };
        c->bit_rate = 800000;
        c->codec_type = AVMEDIA_TYPE_VIDEO;
        c->codec_id = codecType;
        
        
        c->time_base       =  (AVRational){ 1, videoFrameRate };
        o_video_stream->time_base = c->time_base ;
        
        printf("1AVCodec(%d.%d)  AVStream(%d.%d)\n",c ->time_base.num,c ->time_base.den,o_video_stream->time_base.num,o_video_stream->time_base.den);
        
        
        c->width = videoWidth;
        c->height = videoHeight;
        c->pix_fmt =0;
        c->flags = 0;
        if (formatContext->oformat->flags & AVFMT_GLOBALHEADER) {
            c->flags |= AV_CODEC_FLAG_GLOBAL_HEADER;
        }
        
        
        av_dump_format(formatContext, 0, fileCharPath, 1);
        
        ret = avio_open(&formatContext->pb, fileCharPath, AVIO_FLAG_WRITE);
        if (ret < 0) {
            printf("open io failed!");
            return nil;
        }
        
        ret = avformat_write_header(formatContext, NULL);
        if (ret < 0) {
            printf("write header failed!");
            return nil;
        }
        
            //            AVCodec *codec = avcodec_find_decoder(pFormat->o_video_stream->codecpar->codec_id);
            //            c = avcodec_alloc_context3(codec);
        
            //        AVCodecParameters *parameters = pFormat->o_video_stream->codecpar;
            //        parameters->bit_rate = 400000;
            //        parameters->codec_type = AVMEDIA_TYPE_VIDEO;
            //        parameters->codec_id = RF_ConvertCode(pVideoStream->codec_id);
            //        parameters->width = pVideoStream->video_width;
            //        parameters->height = pVideoStream->video_height;
            //        parameters->format = 0;
            //        pFormat->o_video_stream->event_flags = 0;
            //
            //
        
            
        
        
        //    if( pAudioStream != NULL )
        //    {
        //        AVCodec * AudioCodec = NULL;
        //
        //        if(   pAudioStream->codec_id == CODECID_A_PCM )
        //        {
        //            pFormat->o_audio_stream = avformat_new_stream(pFormat->o_fmt_ctx, NULL);
        //        }else
        //        {
        //            AudioCodec  = avcodec_find_encoder(RF_ConvertCode(pAudioStream->codec_id));
        //             if (!AudioCodec) {
        //                    fprintf(stderr, "Could not find encoder for '%s'\n",avcodec_get_name(RF_ConvertCode(pAudioStream->codec_id)));
        //                    exit(1);
        //                }
        //
        //             pFormat->o_audio_stream = avformat_new_stream(pFormat->o_fmt_ctx, AudioCodec);
        //        }
        //
        //        {
        //            AVCodecContext *c;
        //            c = pFormat->o_audio_stream->codec;
        //            c->codec_type = AVMEDIA_TYPE_AUDIO;
        //            c->codec_id = RF_ConvertCode(pAudioStream->codec_id);
        //            c->sample_fmt  = RF_ConvertAudioBitWitdh(pAudioStream->audio_sample_fmt);
        //            c->sample_rate = pAudioStream->audio_sample_rate;
        //            c->channel_layout = RF_ConvertAudioMode(pAudioStream->audio_channel_layout);
        //            c->channels        = av_get_channel_layout_nb_channels(c->channel_layout);
        //            pFormat->o_audio_stream->time_base = (AVRational){ 1, c->sample_rate };
        //            c->time_base       =   pFormat->o_audio_stream->time_base;
        //
        //            /*
        //
        //
        //            c->codec_type = AVMEDIA_TYPE_AUDIO;
        //            c->codec_id = AV_CODEC_ID_AC3;
        //            c->sample_fmt  = AV_SAMPLE_FMT_S16;
        //            c->bit_rate    = 128000;
        //            c->sample_rate = 8000;
        //            c->channel_layout = AV_CH_LAYOUT_MONO;
        //            c->channels        = av_get_channel_layout_nb_channels(c->channel_layout);
        //            printf("1audio channels=%d channel_layout=%d\n", c->channels,c->channel_layout);
        //            pFormat->o_audio_stream->time_base = (AVRational){ 1, c->sample_rate };
        //            c->time_base       =   pFormat->o_audio_stream->time_base;
        //            */
        //
        //            if (pFormat->o_fmt_ctx->oformat->flags & AVFMT_GLOBALHEADER)
        //                c->flags |= CODEC_FLAG_GLOBAL_HEADER;
        //
        //
        //            if( pAudioStream->codec_id == CODECID_A_PCM)
        //            {
        //                if( pAudioStream->audio_sample_rate == 8000)
        //                    pFormat->audio_duration = 160;
        //                else
        //                    pFormat->audio_duration = 160;
        //
        //                c->bit_rate    =   128000;
        //                // c->frame_size   = 640;
        //            }else if( pAudioStream->codec_id == CODECID_A_AC3)
        //            {
        //            /*
        //                if( pAudioStream->audio_sample_rate == 8000)
        //                    pFormat->audio_duration = 1536;
        //                else
        //                    pFormat->audio_duration = 1536;
        //
        //                c->bit_rate    =   12800;
        //            *///    c->frame_size   = 320;
        //                c->sample_fmt  = AV_SAMPLE_FMT_FLTP;
        //                open_audio(AudioCodec,pFormat,NULL);
        //
        //            }else if( pAudioStream->codec_id == CODECID_A_AAC)
        //            {
        //                //c->sample_fmt  = AV_SAMPLE_FMT_FLTP;
        //                //c->channel_layout = AV_CH_LAYOUT_STEREO;
        //                //c->channels = 2;
        //                //c->sample_rate = 11025;
        //                c->bit_rate    =   24000;
        //
        //                open_audio(AudioCodec,pFormat,NULL);
        //            }
        //            else if( pAudioStream->codec_id == CODECID_A_MP3)
        //            {
        //                c->sample_rate = 24000;
        //
        //                open_audio(AudioCodec,pFormat,NULL);
        //            }
        //
        //
        //
        //        }
        //
        //    }
    record.formatContext = formatContext;
    record.o_video_stream = o_video_stream;
    return record;
}

+ (instancetype)recordFileWithFilePath:(NSString *)filePath
                             codecType:(NSInteger)codecType
                            videoWidth:(NSInteger)videoWidth
                           videoHeight:(NSInteger)videoHeight
                        videoFrameRate:(NSInteger)videoFrameRate
                     audioSampleFormat:(NSInteger)audioSampleFormat
                       audioSampleRate:(NSInteger)audioSampleRate
                    audioChannelLayout:(NSInteger)audioChannelLayout
                         audioChannels:(NSInteger)audioChannels {
    return nil;
}

- (void)writeVideoFrame:(void *)data length:(NSInteger)length {
    
        int8_t *pData = data;
        int iLen = length;
        int ret = 0;
        AVPacket i_pkt;
        av_init_packet(&i_pkt);
        i_pkt.size = iLen;
        i_pkt.data = pData;
        
        // h264 ∂±
        if( pData[0] == 0x0 && pData[1] == 0x0 && pData[2] == 0x0 && pData[3] == 0x1 && (pData[4]&0x0f) == (0x67&0x0f) )
        {
            AVCodecContext *c = self.o_video_stream->codec;
//            c = pFormat->o_video_stream->codec;
            if( c->extradata_size == 0 )
            {
                int nalus_num = 0;
                char * ptrBuf = NULL;
                int num = 0;
                ptrBuf = pData;
                if( (ptrBuf[4] & 0x0f) == (0x67 & 0x0f) )
                {
                    for(num = 0; num < 80; num++)
                    {
                        if( ptrBuf[num]  == 0x65 )
                        {
                            nalus_num = num - 4;
                            
                            
                            memcpy(self.strH264Nalu,ptrBuf,nalus_num);
                            self.iH264NaluSize = nalus_num;
                            c->extradata = (unsigned char*)self.strH264Nalu;
                            c->extradata_size = self.iH264NaluSize;
                            
                            {
                                int i = 0;
                                for( i = 0; i < c->extradata_size;i++)
                                {
                                    printf("%x ",c->extradata[i]);
                                    
                                }
                                printf("[%d]\n",c->extradata_size);
                            }
                            
                            break;
                        }
                    }
                }
            }
            
            
            i_pkt.flags |= AV_PKT_FLAG_KEY;
        }
        
        //h265 ∂±
        if( pData[0] == 0x0 && pData[1] == 0x0 && pData[2] == 0x0 && pData[3] == 0x1 &&  pData[4] == 0x40  )
        {
            AVCodecContext *c = self.o_video_stream->codec;
//            if( c->extradata_size == 0 )
//            {
//                int nalus_num = 0;
//                char * ptrBuf = NULL;
//                int num = 0;
//                ptrBuf = pData;
////                if( ptrBuf[4] == 0x40 )
////                {
////                    for(num = 0; num < MAX_NALUS_SZIE; num++)
////                    {
////                        if( num >= iLen )
////                        {
////                            printf("not get nalus\n");
////                            break;
////                        }
////
////                        if( (ptrBuf[num]  == 0x4e && ptrBuf[num-1]  == 0x1  && ptrBuf[num-2]  == 0x0) ||
////                           (ptrBuf[num]  == 0x26 && ptrBuf[num-1]  == 0x1  && ptrBuf[num-2]  == 0x0) )
////                        {
////                            nalus_num = num - 4;
////
////
////                            memcpy(self.strH264Nalu,ptrBuf,nalus_num);
////                            self.iH264NaluSize = nalus_num;
////                            c->extradata = (unsigned char*)self.strH264Nalu;
////                            c->extradata_size = self.iH264NaluSize;
////
////                            {
////                                int i = 0;
////                                for( i = 0; i < c->extradata_size;i++)
////                                {
////                                    printf("%x ",c->extradata[i]);
////
////                                }
////                                printf("[%d]\n",c->extradata_size);
////                            }
////
////                            nalus_num = num - 4;
////                            i_pkt.data = pData + nalus_num;
////                            i_pkt.size = iLen - nalus_num;
////
////                            break;
////                        }
////                    }
////                }
////            }else
////            {
////                int nalus_num = 0;
////                char * ptrBuf = NULL;
////                int num = 0;
////                ptrBuf = pData;
////                if( ptrBuf[4] == 0x40 )
////                {
////                    for(num = 0; num < MAX_NALUS_SZIE; num++)
////                    {
////                        if( num >= iLen )
////                        {
////                            break;
////                        }
////
////                        if( (ptrBuf[num]  == 0x4e && ptrBuf[num-1]  == 0x1  && ptrBuf[num-2]  == 0x0) ||
////                           (ptrBuf[num]  == 0x26 && ptrBuf[num-1]  == 0x1  && ptrBuf[num-2]  == 0x0) )
////                        {
////                            nalus_num = num - 4;
////                            i_pkt.data = pData + nalus_num;
////                            i_pkt.size = iLen - nalus_num;
////                            break;
////                        }
////                    }
////                }
//            }
            
            i_pkt.flags |= AV_PKT_FLAG_KEY;
        }
        
        //if( i_pkt.flags & AV_PKT_FLAG_KEY )
        //    DPRINTK("[%d] %x %x %x %x %x %x\n",i_pkt.size,i_pkt.data[0],i_pkt.data[1],i_pkt.data[2],i_pkt.data[3],i_pkt.data[4],i_pkt.data[5]);
        
        i_pkt.dts = self.v_dts;
        i_pkt.pts = self.v_pts;
    
    ret = [self writeFrame:_formatContext time_base:&_o_video_stream->codec->time_base stream:_o_video_stream packet:&i_pkt];
//        ret = write_frame(_formatContext,&_o_video_stream->codec->time_base,_o_video_stream,&i_pkt);
    
        self.v_dts++;
        self.v_pts++;
    
}

- (int)writeFrame:(AVFormatContext*)fmt_ctx time_base:(AVRational *)time_base stream:(AVStream *)stream packet:(AVPacket *)pkt {
    /* rescale output packet timestamp values from codec to stream timebase */
    av_packet_rescale_ts(pkt, *time_base, stream->time_base);
    pkt->stream_index = stream->index;
    
    //log_packet(fmt_ctx, pkt);
    return av_interleaved_write_frame(fmt_ctx, pkt);
}

- (void)writeAudioFrame:(void *)data length:(NSInteger)length {
    
}

- (void)stopRecord {
    if( _formatContext )
    {
        av_write_trailer(_formatContext);
        
//        if( pFormat->o_audio_stream )
//        {
//            avcodec_close(pFormat->o_audio_stream->codec);
//            av_frame_free(&pFormat->frame);
//            av_frame_free(&pFormat->tmp_frame);
//            swr_free(&pFormat->swr_ctx);
//        }
        
        
        if( _o_video_stream )
        {
            _o_video_stream->codec->extradata_size = 0;
            _o_video_stream->codec->extradata = NULL;
            
            avcodec_close(_o_video_stream->codec);
        }
        
        avio_close(_formatContext->pb);
        avformat_free_context(_formatContext);
    }
}

@end
