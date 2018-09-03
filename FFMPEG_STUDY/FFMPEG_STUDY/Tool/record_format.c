
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>


#include <libavutil/avassert.h>
#include <libavutil/channel_layout.h>
#include <libavutil/opt.h>
#include <libavutil/mathematics.h>
#include <libavutil/timestamp.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libswresample/swresample.h>


#include "rjone_config.h"
#include "rjone.h"
#include "rjone_debug.h"
#include "record_format.h"


#ifdef USE_RECORD_MODULE


#define STREAM_DURATION   60.0
#define STREAM_FRAME_RATE 25 /* 25 images/s */
#define STREAM_PIX_FMT    AV_PIX_FMT_YUV420P /* default pix_fmt */
#define MAX_NALUS_SZIE (5000)

#define AUDIO_BUF_SIZE (8192)

#define SCALE_FLAGS SWS_BICUBIC

// a wrapper around a single output AVStream
typedef struct OutputStream {
	AVStream *st;

	/* pts of the next frame that will be generated */
	int64_t next_pts;
	int samples_count;

	AVFrame *frame;
	AVFrame *tmp_frame;

	float t, tincr, tincr2;

	struct SwsContext *sws_ctx;
	struct SwrContext *swr_ctx;
} OutputStream;


typedef struct _RECORD_FORMAT_
{
	char filename[256];
	AVFormatContext * o_fmt_ctx; 
	AVStream * o_video_stream;
	AVStream * o_audio_stream;
	int audio_duration;
	int64_t v_pts;
	int64_t v_dts; 
	int64_t a_pts;
	int64_t a_dts; 	
       AVFrame *frame;
    	AVFrame *tmp_frame;

	  /* pts of the next frame that will be generated */
        int64_t next_pts;
      int samples_count;
    	float t, tincr, tincr2;
    
    	struct SwrContext *swr_ctx;
	char strH264Nalu[MAX_NALUS_SZIE];
	int iH264NaluSize;	
	char AudioBuf[AUDIO_BUF_SIZE];
	int iAudioPos;
}RECORD_FORMAT;


typedef struct _FILE_PLAY_
{
	AVFormatContext  *ic;
	AVPacket  readpacket;
	AVBitStreamFilterContext* pVideoFilter;		
	AVFrame * pAudioFrame;
	AVCodecContext *pAudioCode;
	unsigned char strAudioBuf[AUDIO_BUF_SIZE];	
	int iAudioLen;
	int frame_ms;  //多少毫秒一帧
	int oldframe;  //上一次的时间   毫秒
	int allsecs;
	int hours;
	int mins;
	int secs;
	int us;    //文件时长
	RECORD_FILE_INFO stFileInfo;
	int64_t now_file_dts;
	unsigned char strH265_VPS_SPS_PPS_Nalu[MAX_NALUS_SZIE];
	int h265_vps_sps_pps_nalus_len;
	unsigned char * h265_VideoBuf;
}FILE_PLAY;



int RF_ConvertCode(int iCode)
{
	int iConvretCode = 0;

	switch(iCode)
	{
	case CODECID_V_H264: iConvretCode = AV_CODEC_ID_H264; break;
	case CODECID_A_PCM: iConvretCode = AV_CODEC_ID_PCM_S16LE; break;
	case CODECID_A_AAC: iConvretCode = AV_CODEC_ID_AAC; break;
	case CODECID_A_AC3: iConvretCode = AV_CODEC_ID_AC3; break;
	case CODECID_A_MP3: iConvretCode = AV_CODEC_ID_MP3; break;
	case CODECID_V_H265: iConvretCode = AV_CODEC_ID_HEVC; break;
	
	default:break;
	}	
	return iConvretCode;
}


int RF_ConvertCodeBack(int iCode)
{
	int iConvretCode = 0;

	switch(iCode)
	{
	case AV_CODEC_ID_H264: iConvretCode = CODECID_V_H264; break;
	case AV_CODEC_ID_PCM_S16LE: iConvretCode = CODECID_A_PCM; break;
	case AV_CODEC_ID_AAC: iConvretCode = CODECID_A_AAC; break;
	case AV_CODEC_ID_AC3: iConvretCode = CODECID_A_AC3; break;
	case AV_CODEC_ID_MP3: iConvretCode = CODECID_A_MP3; break;
	case AV_CODEC_ID_HEVC: iConvretCode = CODECID_V_H265; break;
	default:break;
	}	
	return iConvretCode;
}

int RF_ConvertAudioBitWitdh(int iBitWidth)
{
	int iConvertWidth= 0;

	switch(iBitWidth)
	{
	case ADATABITS_8: iConvertWidth = AV_SAMPLE_FMT_U8; break;
	case ADATABITS_16: iConvertWidth = AV_SAMPLE_FMT_S16; break;
	default:break;		
	}	
	return iConvertWidth;
}

int RF_ConvertAudioBitWitdhBack(int iBitWidth)
{
	int iConvertWidth= 0;

	switch(iBitWidth)
	{
	case AV_SAMPLE_FMT_U8: iConvertWidth = ADATABITS_8; break;
	case AV_SAMPLE_FMT_S16: iConvertWidth = ADATABITS_16; break;
	default:break;		
	}	
	return iConvertWidth;
}


int RF_ConvertAudioMode(int iMode)
{
	int iConvertMode= 0;

	switch(iMode)
	{
	case ACHANNEL_MONO: iConvertMode = AV_CH_LAYOUT_MONO; break;
	case ACHANNEL_STEREO: iConvertMode = AV_CH_LAYOUT_STEREO; break;
	default:break;		
	}	
	return iConvertMode;
}

int RF_ConvertAudioModeBack(int iMode)
{
	int iConvertMode= 0;

	switch(iMode)
	{
	case AV_CH_LAYOUT_MONO: iConvertMode = ACHANNEL_MONO; break;
	case AV_CH_LAYOUT_STEREO: iConvertMode = ACHANNEL_STEREO; break;
	default:break;		
	}	
	return iConvertMode;
}



int RF_InitFormatLib()
{
	static int first = 0;

	if( first == 0 )
	{
		DPRINTK("av_register_all \n");
		av_register_all();
		first = 1;
	}

	return RJONE_SUCCESS;
}

int RF_DestroyFormatLib()
{
	return RJONE_SUCCESS;
}

static void log_packet(const AVFormatContext *fmt_ctx, const AVPacket *pkt)
{
	AVRational *time_base = &fmt_ctx->streams[pkt->stream_index]->time_base;

	printf("pts:%s pts_time:%s dts:%s dts_time:%s duration:%s duration_time:%s stream_index:%d  time_base(%d.%d)\n",
		av_ts2str(pkt->pts), av_ts2timestr(pkt->pts, time_base),
		av_ts2str(pkt->dts), av_ts2timestr(pkt->dts, time_base),
		av_ts2str(pkt->duration), av_ts2timestr(pkt->duration, time_base),
		pkt->stream_index,time_base->num,time_base->den);
}


static int write_frame(AVFormatContext *fmt_ctx, const AVRational *time_base, AVStream *st, AVPacket *pkt)
{
	/* rescale output packet timestamp values from codec to stream timebase */
	av_packet_rescale_ts(pkt, *time_base, st->time_base);
	pkt->stream_index = st->index;

	//log_packet(fmt_ctx, pkt);
	return av_interleaved_write_frame(fmt_ctx, pkt);
}


/**************************************************************/
/* audio output */

static AVFrame *alloc_audio_frame(enum AVSampleFormat sample_fmt,
                                  uint64_t channel_layout,
                                  int sample_rate, int nb_samples)
{
    AVFrame *frame = av_frame_alloc();
    int ret;

    if (!frame) {
        fprintf(stderr, "Error allocating an audio frame\n");
        exit(1);
    }

    frame->format = sample_fmt;
    frame->channel_layout = channel_layout;
    frame->sample_rate = sample_rate;
    frame->nb_samples = nb_samples;

    if (nb_samples) {		

	DPRINTK("nb_samples=%d  channel_layout=%llu sample_fmt=%d sample_rate=%d\n",nb_samples,channel_layout,sample_fmt,sample_rate);
        ret = av_frame_get_buffer(frame, 0);
        if (ret < 0) {
            fprintf(stderr, "Error allocating an audio buffer\n");
            exit(1);
        }
    }

    return frame;
}


static void open_audio( AVCodec *codec, RECORD_FORMAT *ost, AVDictionary *opt_arg)
{
    AVCodecContext *c;
    int nb_samples;
    int ret;
    AVDictionary *opt = NULL;

    c = ost->o_audio_stream->codec;

    /* open it */
    //av_dict_copy(&opt, opt_arg, 0);
    ret = avcodec_open2(c, codec, &opt);
    //av_dict_free(&opt);
    if (ret < 0) {
        fprintf(stderr, "Could not open audio codec: %s\n", av_err2str(ret));
        exit(1);
    }


    ost->t     = 0;
    ost->tincr = 2 * M_PI * 110.0 / c->sample_rate;
    ost->tincr2 = 2 * M_PI * 110.0 / c->sample_rate / c->sample_rate;

   if (c->codec->capabilities & CODEC_CAP_VARIABLE_FRAME_SIZE)
        nb_samples = 10000;
    else
        nb_samples = c->frame_size;

    DPRINTK("nb_samples=%d\n",nb_samples);

    ost->frame     = alloc_audio_frame(c->sample_fmt, c->channel_layout,
                                       c->sample_rate, nb_samples);
    ost->tmp_frame = alloc_audio_frame(AV_SAMPLE_FMT_S16, c->channel_layout,
                                       c->sample_rate, nb_samples);

    /* create resampler context */
        ost->swr_ctx = swr_alloc();
        if (!ost->swr_ctx) {
            fprintf(stderr, "Could not allocate resampler context\n");
            exit(1);
        }

        /* set options */
        av_opt_set_int       (ost->swr_ctx, "in_channel_count",   c->channels,       0);
        av_opt_set_int       (ost->swr_ctx, "in_sample_rate",     c->sample_rate,    0);
        av_opt_set_sample_fmt(ost->swr_ctx, "in_sample_fmt",      AV_SAMPLE_FMT_S16, 0);
        av_opt_set_int       (ost->swr_ctx, "out_channel_count",  c->channels,       0);
        av_opt_set_int       (ost->swr_ctx, "out_sample_rate",    c->sample_rate,    0);
        av_opt_set_sample_fmt(ost->swr_ctx, "out_sample_fmt",     c->sample_fmt,     0);

        /* initialize the resampling context */
        if ((ret = swr_init(ost->swr_ctx)) < 0) 
	{
            fprintf(stderr, "Failed to initialize the resampling context\n");
            exit(1);
        }
}




/* Prepare a 16 bit dummy audio frame of 'frame_size' samples and
 * 'nb_channels' channels. */
static AVFrame *get_audio_frame(RECORD_FORMAT *ost,char * pData)
{
    AVFrame *frame = ost->tmp_frame;
    int j, i, v;
    int16_t *q = (int16_t*)frame->data[0];

	if(1)
	{
		memcpy(frame->data[0],pData,frame->nb_samples*2);
	}else
	{	
	    for (j = 0; j <frame->nb_samples; j++) {
	        v = (int)(sin(ost->t) * 10000);
	        for (i = 0; i < ost->o_audio_stream->codec->channels; i++)
	            *q++ = v;
	        ost->t     += ost->tincr;
	        ost->tincr += ost->tincr2;
	    }	    	
	}	

    frame->pts = ost->next_pts;
    ost->next_pts  += frame->nb_samples;

    return frame;
}


/*
 * encode one audio frame and send it to the muxer
 * return 1 when encoding is finished, 0 otherwise
 */
static int write_audio_frame(AVFormatContext *oc, RECORD_FORMAT *ost,char * pData)
{
    AVCodecContext *c;
    AVPacket pkt = { 0 }; // data and size must be 0;
    AVFrame *frame;
    int ret;
    int got_packet;
    int dst_nb_samples;

    av_init_packet(&pkt);
    c = ost->o_audio_stream->codec;

    frame = get_audio_frame(ost,pData);

    if (frame) {
        /* convert samples from native format to destination codec format, using the resampler */
            /* compute destination number of samples */
            dst_nb_samples = av_rescale_rnd(swr_get_delay(ost->swr_ctx, c->sample_rate) + frame->nb_samples,
                                            c->sample_rate, c->sample_rate, AV_ROUND_UP);
            av_assert0(dst_nb_samples == frame->nb_samples);

        /* when we pass a frame to the encoder, it may keep a reference to it
         * internally;
         * make sure we do not overwrite it here
         */
        ret = av_frame_make_writable(ost->frame);
        if (ret < 0)
           return -1;

            /* convert to destination format */
            ret = swr_convert(ost->swr_ctx,
                              ost->frame->data, dst_nb_samples,
                              (const uint8_t **)frame->data, frame->nb_samples);
            if (ret < 0) {
                fprintf(stderr, "Error while converting\n");
                return -1;
            }
            frame = ost->frame;

        frame->pts = av_rescale_q(ost->samples_count, (AVRational){1, c->sample_rate}, c->time_base);
        ost->samples_count += dst_nb_samples;
    }

    ret = avcodec_encode_audio2(c, &pkt, frame, &got_packet);
    if (ret < 0) {
        fprintf(stderr, "Error encoding audio frame: %s\n", av_err2str(ret));
        return -1;
    }

//	DPRINTK("encode %d\n",got_packet);


    if (got_packet) {
        ret = write_frame(oc, &c->time_base, ost->o_audio_stream, &pkt);
        if (ret < 0) {
            fprintf(stderr, "Error while writing audio frame: %s\n",
                    av_err2str(ret));
            return -1;
        }
    }

    return (frame || got_packet) ? 0 : 1;
}


int RF_ReSetRecordFileVideoInfo(HANDLE  hHandle,int fps,int width,int height,int codec)
{
	

	return 0;
}


HANDLE RF_CreateRecordFile(char * pFileName,RECORD_FORAMT_STREAM_INFO * pVideoStream,RECORD_FORAMT_STREAM_INFO * pAudioStream)
{
	RECORD_FORMAT * pFormat = NULL;

//    pFormat = (RECORD_FORMAT*)Debug_Malloc(sizeof(RECORD_FORMAT));

    pFormat = malloc(sizeof(RECORD_FORMAT));
	memset(pFormat,0x00,sizeof(RECORD_FORMAT));

	/* allocate the output media context */
	avformat_alloc_output_context2(&pFormat->o_fmt_ctx, NULL, NULL, pFileName);
	if (!pFormat->o_fmt_ctx)
	{
		DPRINTK("Could not deduce output format from file extension\n");
        return NULL;
	}

	strcpy(pFormat->filename,pFileName);


	if( pVideoStream != NULL )
	{
		pFormat->o_video_stream = avformat_new_stream(pFormat->o_fmt_ctx, NULL); 
		{ 
			AVCodecContext *c; 
			c = pFormat->o_video_stream->codec; 
			c->bit_rate = 400000; 
			c->codec_type = AVMEDIA_TYPE_VIDEO; 
			c->codec_id = RF_ConvertCode(pVideoStream->codec_id); 

			c->time_base       =  (AVRational){ 1, pVideoStream->video_framerate };
			pFormat->o_video_stream->time_base = c->time_base ;		
			{
				AVCodecContext *c;
				c = pFormat->o_video_stream->codec;
				printf("1AVCodec(%d.%d)  AVStream(%d.%d)\n",c ->time_base.num,c ->time_base.den,pFormat->o_video_stream->time_base.num,pFormat->o_video_stream->time_base.den);

			}

			c->width = pVideoStream->video_width; 
			c->height = pVideoStream->video_height; 
			c->pix_fmt =0;    
			c->flags = 0; 
			if (pFormat->o_fmt_ctx->oformat->flags & AVFMT_GLOBALHEADER)
				c->flags |= CODEC_FLAG_GLOBAL_HEADER; 	
		}
	}


	if( pAudioStream != NULL )
	{
		int ret = 0;
		AVCodec * AudioCodec = NULL;

		if(   pAudioStream->codec_id == CODECID_A_PCM )
		{
			pFormat->o_audio_stream = avformat_new_stream(pFormat->o_fmt_ctx, NULL); 
		}else
		{
			AudioCodec  = avcodec_find_encoder(RF_ConvertCode(pAudioStream->codec_id));
			 if (!AudioCodec) {
			        fprintf(stderr, "Could not find encoder for '%s'\n",avcodec_get_name(RF_ConvertCode(pAudioStream->codec_id)));
			        exit(1);
	   		 }	

			 pFormat->o_audio_stream = avformat_new_stream(pFormat->o_fmt_ctx, AudioCodec); 
		}		
		
		{ 
			AVCodecContext *c; 
			c = pFormat->o_audio_stream->codec;
			c->codec_type = AVMEDIA_TYPE_AUDIO; 
			c->codec_id = RF_ConvertCode(pAudioStream->codec_id); 
			c->sample_fmt  = RF_ConvertAudioBitWitdh(pAudioStream->audio_sample_fmt);	       
			c->sample_rate = pAudioStream->audio_sample_rate;
			c->channel_layout = RF_ConvertAudioMode(pAudioStream->audio_channel_layout);
			c->channels        = av_get_channel_layout_nb_channels(c->channel_layout);	
			pFormat->o_audio_stream->time_base = (AVRational){ 1, c->sample_rate };		
			c->time_base       =   pFormat->o_audio_stream->time_base;

			/*	


			c->codec_type = AVMEDIA_TYPE_AUDIO; 
			c->codec_id = AV_CODEC_ID_AC3;        
			c->sample_fmt  = AV_SAMPLE_FMT_S16;
			c->bit_rate    = 128000;
			c->sample_rate = 8000;
			c->channel_layout = AV_CH_LAYOUT_MONO;
			c->channels        = av_get_channel_layout_nb_channels(c->channel_layout);
			printf("1audio channels=%d channel_layout=%d\n", c->channels,c->channel_layout);
			pFormat->o_audio_stream->time_base = (AVRational){ 1, c->sample_rate };		
			c->time_base       =   pFormat->o_audio_stream->time_base;
			*/		

			if (pFormat->o_fmt_ctx->oformat->flags & AVFMT_GLOBALHEADER)
				c->flags |= CODEC_FLAG_GLOBAL_HEADER; 	
			

			if( pAudioStream->codec_id == CODECID_A_PCM)
			{
				if( pAudioStream->audio_sample_rate == 8000)
					pFormat->audio_duration = 160;
				else
					pFormat->audio_duration = 160;

				c->bit_rate    =   128000;
				// c->frame_size   = 640;
			}else if( pAudioStream->codec_id == CODECID_A_AC3)
			{
			/*
				if( pAudioStream->audio_sample_rate == 8000)
					pFormat->audio_duration = 1536;
				else
					pFormat->audio_duration = 1536;

				c->bit_rate    =   12800;
			*///	c->frame_size   = 320;
				c->sample_fmt  = AV_SAMPLE_FMT_FLTP;
				open_audio(AudioCodec,pFormat,NULL);
				
			}else if( pAudioStream->codec_id == CODECID_A_AAC)
			{			
				//c->sample_fmt  = AV_SAMPLE_FMT_FLTP;
				//c->channel_layout = AV_CH_LAYOUT_STEREO;
				//c->channels = 2;
				//c->sample_rate = 11025;
				c->bit_rate    =   24000;

				open_audio(AudioCodec,pFormat,NULL);
			}
			else if( pAudioStream->codec_id == CODECID_A_MP3)
			{						
				c->sample_rate = 24000;	

				open_audio(AudioCodec,pFormat,NULL);
			}
				
		}
	}

	av_dump_format(pFormat->o_fmt_ctx, 0, pFormat->filename, 1);
	
	avio_open(&pFormat->o_fmt_ctx->pb, pFormat->filename, AVIO_FLAG_WRITE);
	
	avformat_write_header(pFormat->o_fmt_ctx, NULL);
	return pFormat;
}






int RF_WriteVideoFrame(HANDLE  hHandle,char * pData,int iLen)
{
	RECORD_FORMAT * pFormat = (RECORD_FORMAT*)hHandle;
	int ret = 0;
	AVPacket i_pkt; 
	av_init_packet(&i_pkt); 
	i_pkt.size = iLen; 
	i_pkt.data = pData; 	

	// h264识别
	if( pData[0] == 0x0 && pData[1] == 0x0 && pData[2] == 0x0 && pData[3] == 0x1 && (pData[4]&0x0f) == (0x67&0x0f) )
	{
		AVCodecContext *c; 
		c = pFormat->o_video_stream->codec;
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

						
						memcpy(pFormat->strH264Nalu,ptrBuf,nalus_num);
						pFormat->iH264NaluSize = nalus_num;
						c->extradata = (unsigned char*)pFormat->strH264Nalu;						
						c->extradata_size = pFormat->iH264NaluSize;

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

	//h265识别
	if( pData[0] == 0x0 && pData[1] == 0x0 && pData[2] == 0x0 && pData[3] == 0x1 &&  pData[4] == 0x40  )
	{
		AVCodecContext *c; 		
		c = pFormat->o_video_stream->codec;
		if( c->extradata_size == 0 )
		{			
			int nalus_num = 0;
			char * ptrBuf = NULL;
			int num = 0;
			ptrBuf = pData;
			if( ptrBuf[4] == 0x40 )		
			{				
				for(num = 0; num < MAX_NALUS_SZIE; num++)
				{
					if( num >= iLen )
					{
						printf("not get nalus\n");
						break;
					}
				
					if( ptrBuf[num]  == 0x4e && ptrBuf[num-1]  == 0x1  && ptrBuf[num-2]  == 0x0 )
					{
						nalus_num = num - 4;

						
						memcpy(pFormat->strH264Nalu,ptrBuf,nalus_num);
						pFormat->iH264NaluSize = nalus_num;
						c->extradata = (unsigned char*)pFormat->strH264Nalu;						
						c->extradata_size = pFormat->iH264NaluSize;

						{
							int i = 0;
							for( i = 0; i < c->extradata_size;i++)
							{
								printf("%x ",c->extradata[i]);
								
							}
							printf("[%d]\n",c->extradata_size);
						}

						nalus_num = num - 4;
						i_pkt.data = pData + nalus_num; 		
						i_pkt.size = iLen - nalus_num; 
						
						break;
					}
				}					
			}
		}else
		{
			int nalus_num = 0;
			char * ptrBuf = NULL;
			int num = 0;
			ptrBuf = pData;			
			if( ptrBuf[4] == 0x40 )		
			{							
				for(num = 0; num < MAX_NALUS_SZIE; num++)
				{
					if( num >= iLen )
					{						
						break;
					}
				
					if( ptrBuf[num]  == 0x4e && ptrBuf[num-1]  == 0x1  && ptrBuf[num-2]  == 0x0 )
					{						
						nalus_num = num - 4;
						i_pkt.data = pData + nalus_num; 		
						i_pkt.size = iLen - nalus_num; 
						break;
					}
				}					
			}
		}
		
		i_pkt.flags |= AV_PKT_FLAG_KEY;
	}

	//if( i_pkt.flags & AV_PKT_FLAG_KEY )
	//	DPRINTK("[%d] %x %x %x %x %x %x\n",i_pkt.size,i_pkt.data[0],i_pkt.data[1],i_pkt.data[2],i_pkt.data[3],i_pkt.data[4],i_pkt.data[5]);

	i_pkt.dts = pFormat->v_dts;
	i_pkt.pts = pFormat->v_pts;		   	

	ret = write_frame(pFormat->o_fmt_ctx,&pFormat->o_video_stream->codec->time_base,pFormat->o_video_stream,&i_pkt);

	pFormat->v_dts++;
	pFormat->v_pts++;

	if( ret >= 0 )
		return RJONE_SUCCESS;

	return -1;
}


int RF_WriteAudioFrame(HANDLE  hHandle,char * pData,int iLen)
{
	RECORD_FORMAT * pFormat = (RECORD_FORMAT*)hHandle;	
	char * AudioBuf = NULL;
	char tmpBuf[8192];
	int ret = 0;

	AudioBuf = pFormat->AudioBuf;

	AVPacket i_pkt; 
	av_init_packet(&i_pkt); 
	i_pkt.size = iLen; 
	i_pkt.data = pData; 


	if( pFormat->o_audio_stream->codec->codec_id == AV_CODEC_ID_PCM_S16LE)
	{
		i_pkt.flags |= AV_PKT_FLAG_KEY;   

		i_pkt.dts = pFormat->a_dts;
		i_pkt.pts = pFormat->a_pts;	
		i_pkt.duration =  pFormat->audio_duration;
		pFormat->a_dts += i_pkt.duration;
		pFormat->a_pts += i_pkt.duration;
		write_frame(pFormat->o_fmt_ctx,&pFormat->o_audio_stream->codec->time_base,pFormat->o_audio_stream,&i_pkt);

		return RJONE_SUCCESS;	
	}

	//DPRINTK("iLen = %d  %d\n",iLen,pFormat->o_audio_stream->codec->frame_size);

	if(  pFormat->iAudioPos + iLen > 8192 )
	{
		DPRINTK("Audio over buf size  %d %d\n", pFormat->iAudioPos, iLen);
		pFormat->iAudioPos = 0;
		return RJONE_FAILED;
	}

	memcpy(AudioBuf+ pFormat->iAudioPos,pData,iLen);
	 pFormat->iAudioPos += iLen;

	//if( pFormat->o_audio_stream->codec->frame_size  != 1024 )
	//	DPRINTK("iLen = %d  %d\n", pFormat->iAudioPos,pFormat->o_audio_stream->codec->frame_size);

	if( ( pFormat->iAudioPos/2) > pFormat->o_audio_stream->codec->frame_size )
	{	
		ret = write_audio_frame(pFormat->o_fmt_ctx,pFormat,AudioBuf);
		if( ret < 0 )
			goto err;

		memcpy(tmpBuf,AudioBuf,8192);
		
		 pFormat->iAudioPos -= pFormat->o_audio_stream->codec->frame_size * 2;

		memcpy(AudioBuf,tmpBuf + pFormat->o_audio_stream->codec->frame_size * 2, pFormat->iAudioPos);

		//DPRINTK(" 2 iLen=%d  frame_size=%d\n",iLen,pFormat->o_audio_stream->codec->frame_size);

	}
	
	return RJONE_SUCCESS;	
err:
	return RJONE_FAILED;
}



int  RF_CloseRecordFile(HANDLE  hHandle)
{
	RECORD_FORMAT * pFormat = (RECORD_FORMAT*)hHandle;	

	if( pFormat )
	{
		av_write_trailer(pFormat->o_fmt_ctx);

		if( pFormat->o_audio_stream )
		{
			avcodec_close(pFormat->o_audio_stream->codec); 	
			av_frame_free(&pFormat->frame);
			av_frame_free(&pFormat->tmp_frame);			
			swr_free(&pFormat->swr_ctx);
		}


		if( pFormat->o_video_stream )
		{
			pFormat->o_video_stream->codec->extradata_size = 0;
			pFormat->o_video_stream->codec->extradata = NULL;
		
			avcodec_close(pFormat->o_video_stream->codec); 			
		}

		avio_close(pFormat->o_fmt_ctx->pb); 
		avformat_free_context(pFormat->o_fmt_ctx);
//        Debug_Free(pFormat);
        free(pFormat);
	}

	return RJONE_SUCCESS;
err:
	return RJONE_FAILED;
}


void Get_H265_VPS_PPS_SPS_NALUS(char * source,int len,char * dest,int * dest_len)
{
	char * data_ptr = source + 23;
	char * save_dest_prt = dest;
	int offset = 23;
	unsigned int nalu_len = 0;
	unsigned char start_code[4] = {0,0,0,1};
	int dest_offset = 0;
	int i = 0;
	int len_tmp = 0;

	while(offset < len )
	{
		data_ptr = data_ptr + 3;
		offset += 3;
		len_tmp = data_ptr[0] ;
		//DPRINTK("len_tmp = %d  %x %x\n",len_tmp,data_ptr[0],data_ptr[1]);
		nalu_len = len_tmp * 255 + data_ptr[1];
		data_ptr = data_ptr +2;
		offset += 2;

		//DPRINTK("nalu_len = %d\n",nalu_len);

		memcpy(dest,start_code,4);		
		dest += 4;
		dest_offset += 4;

		memcpy(dest,data_ptr,nalu_len);	
		data_ptr += nalu_len;
		offset += nalu_len;
		
		dest += nalu_len;
		dest_offset += nalu_len;		
	}

	for( i = 0; i < dest_offset; i++)
	{
		printf("%x ",save_dest_prt[i]);
	}

	printf("\n");

	*dest_len = dest_offset;	
}


void *RF_OpenReadFile(const char *ofile)
{
	int i;
	FILE_PLAY * pFile = NULL;
	int videoStream = -1; // Didn't find a video stream
	int audioStream = -1; // Didn't find a audio stream

//    pFile = (FILE_PLAY *)Debug_Malloc(sizeof(FILE_PLAY));
    pFile = malloc(sizeof(FILE_PLAY));
	memset(pFile,0x00,sizeof(FILE_PLAY));

	if( pFile == NULL )
	{
		DPRINTK("Debug_Malloc err\n");
		goto err;
	}

	if (avformat_open_input(&pFile->ic, ofile, NULL, NULL) != 0) 
	{		
		DPRINTK("avformat_open_input %s err\n",ofile);
		goto err;
	}

	
	pFile->ic ->max_analyze_duration = 1000;

	av_init_packet(&pFile->readpacket);

	
	if(avformat_find_stream_info(pFile->ic,NULL) < 0)
	{		
		DPRINTK("avformat_find_stream_info %s err\n",ofile);
		goto err;
	}
	
	av_dump_format(pFile->ic, 0, ofile, 0);
	
	//find stream
	for ( i = 0; i < pFile->ic ->nb_streams; i++) 
	{
		if (pFile->ic ->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) 
		{

			//DPRINTK("den=%d  num=%d  \n",pFile->ic ->streams[i]->r_frame_rate.den,pFile->ic ->streams[i]->r_frame_rate.num);
			pFile->stFileInfo.stVideo.video_width = pFile->ic ->streams[i]->codec->width;
			pFile->stFileInfo.stVideo.video_height= pFile->ic ->streams[i]->codec->height;
			pFile->stFileInfo.stVideo.codec_id = RF_ConvertCodeBack(pFile->ic ->streams[i]->codec->codec_id);
			pFile->stFileInfo.stVideo.video_framerate = pFile->ic ->streams[i]->r_frame_rate.num/pFile->ic ->streams[i]->r_frame_rate.den;
			pFile->stFileInfo.iHaveVideoData = 1;
		

			if( strstr(ofile,"mp4") != NULL  && pFile->stFileInfo.stVideo.codec_id == CODECID_V_H264)
			{  
			    uint8_t *dummy = NULL;  
			    int dummy_size;  
			     pFile->pVideoFilter =  av_bitstream_filter_init("h264_mp4toannexb"); 		  
			    if(pFile->pVideoFilter == NULL)  
			    {  
			    	 DPRINTK("av_bitstream_filter_init err\n");
			        goto err;
			    }  				  
			}else if( strstr(ofile,"mp4") != NULL  && pFile->stFileInfo.stVideo.codec_id == CODECID_V_H265)
			{  
					AVCodecContext *c; 
					c = pFile->ic ->streams[i]->codec;

					if( c->extradata_size > 0 )
					{
						Get_H265_VPS_PPS_SPS_NALUS(c->extradata,c->extradata_size,\
							pFile->strH265_VPS_SPS_PPS_Nalu,&pFile->h265_vps_sps_pps_nalus_len);						
					}
				
			}

		
			videoStream = i;
			break;
		}
	}
	// Find the first audio stream
	for ( i = 0; i < pFile->ic ->nb_streams; i++) 
	{
		if (pFile->ic ->streams[i]->codec->codec_type == AVMEDIA_TYPE_AUDIO) 
		{
			pFile->stFileInfo.stAudio.audio_sample_fmt = RF_ConvertAudioBitWitdhBack(pFile->ic ->streams[i]->codec->sample_fmt);
			pFile->stFileInfo.stAudio.audio_sample_rate = pFile->ic ->streams[i]->codec->sample_rate;
			pFile->stFileInfo.stAudio.codec_id = RF_ConvertCodeBack(pFile->ic ->streams[i]->codec->codec_id);
			pFile->stFileInfo.stAudio.audio_channel_layout = RF_ConvertAudioModeBack(pFile->ic ->streams[i]->codec->channel_layout);
			pFile->stFileInfo.iHaveAudioData = 1;

			if( strstr(ofile,"mp4") != NULL )
			{
				int ret = 0;
				AVCodec * pAudioDec;
				AVStream *st;
				AVCodecContext *dec_ctx = NULL;
				 AVCodec *dec = NULL;

				dec_ctx = pFile->ic ->streams[i]->codec;
				
			        dec = avcodec_find_decoder(dec_ctx->codec_id);
			        if (!dec) 
				 {
			            fprintf(stderr, "Failed to find %s codec\n",
			                    av_get_media_type_string(AVMEDIA_TYPE_AUDIO));
			            return AVERROR(EINVAL);
			        }

				  /* init the audio decoder */
				    if ((ret = avcodec_open2(dec_ctx, dec, NULL)) < 0) {
				        av_log(NULL, AV_LOG_ERROR, "Cannot open audio decoder\n");
				        return ret;
				    }

				pFile->pAudioCode = dec_ctx;

				pFile->pAudioFrame = av_frame_alloc();

			}
		
			audioStream = i;
			break;
		}
	}
	//判断视频文件中是否包含音视频流，如果没有，退出
	if (audioStream < 0 && videoStream < 0) 
	{
		DPRINTK("%s no stream err\n",ofile);
		goto err;
	}
	
	pFile->frame_ms = 1000/(pFile->ic->streams[videoStream]->r_frame_rate.num/pFile->ic->streams[videoStream]->r_frame_rate.den);

	pFile->allsecs = pFile->ic->duration / AV_TIME_BASE;
	pFile->us = pFile->ic->duration % AV_TIME_BASE;
	pFile->mins = pFile->allsecs / 60;
	pFile->secs = pFile->allsecs % 60;
	pFile->hours = pFile->mins / 60;
	pFile->mins %= 60;

	pFile->stFileInfo.iFileRecSecs = pFile->allsecs ;
	
	return pFile;		
err:

	if( pFile )
	{
		if( pFile->ic )
		  {
		  	av_free_packet(&pFile->readpacket);
		  	avformat_close_input(&pFile->ic);
			if (pFile->ic != NULL) 
			{
				av_read_pause(pFile->ic);
				avformat_free_context(pFile->ic);
				pFile->ic = NULL;
			}
		   }

//        Debug_Free(pFile);
        free(pFile);
	}
	
	return NULL;
}


int  RF_GetFileInfo(void *FileHandle,RECORD_FILE_INFO * pstFileInfo)
{
	FILE_PLAY * pFile = (FILE_PLAY *)FileHandle;
	if(FileHandle == NULL || pstFileInfo == NULL)
	{
		DPRINTK("Input parameters err\n");
		return -1;
	}

	*pstFileInfo = pFile->stFileInfo;
	
	return 1;
}

int RF_filter_packet(AVFormatContext *avf,  AVPacket *pkt,AVBitStreamFilterContext *bsf)
{
    AVStream *st = avf->streams[pkt->stream_index];    
    AVPacket pkt2;
    int ret; 

        av_assert0(pkt->stream_index >= 0);	

        pkt2 = *pkt;
	
       ret = av_bitstream_filter_filter(bsf, st->codec, NULL,&pkt2.data, &pkt2.size,pkt->data, pkt->size,pkt->flags & AV_PKT_FLAG_KEY);	
        if (ret < 0) 
	{
            av_packet_unref(pkt);
            return ret;
        }
      
        av_assert0(pkt2.buf);
        if (ret == 0 && pkt2.data != pkt->data) 
	{
            if ((ret = av_copy_packet(&pkt2, pkt)) < 0) 
	   {
                av_free(pkt2.data);
                return ret;
            }
            ret = 1;
        }
		
        if (ret > 0) 
	{	
            av_free_packet(pkt);
            pkt2.buf = av_buffer_create(pkt2.data, pkt2.size,av_buffer_default_free, NULL, 0);
            if (!pkt2.buf) 
	    {
                av_free(pkt2.data);
                return AVERROR(ENOMEM);
            }
        }
        *pkt = pkt2;    
    	return 0;
}

int ConvertTime(struct timeval * pTime,double timeStick)
{
	double dSec = 0;
	double dUsec = 0;

	dSec = timeStick * 1000;
	dUsec = ((int)dSec % 1000 )* 1000;
	dSec = dSec / 1000;

	pTime->tv_sec = dSec;
	pTime->tv_usec = dUsec;

	return 1;
}


int  RF_ReadFrame(void *FileHandle,char ** pDataAddr,int * iStreamIndex,int * isKeyFrame,int iReadSpeed, struct timeval * pPlayTime)
{
	FILE_PLAY * pFile = (FILE_PLAY *)FileHandle;
	struct timeval tv;
	int datasize;
	int ti = 0;	

	av_free_packet(&pFile->readpacket);

	if(iReadSpeed == 1 )
	{
		if (av_read_frame(pFile->ic, &pFile->readpacket) < 0) 
		{		
			DPRINTK("av_read_frame err\n");
			return -1;
		}
		
		//已视频时间轴为发送时间控制。
		if( pFile->readpacket.stream_index == 0 )
		{
//            gettimeofday(&tv, NULL);
			int newusec = tv.tv_usec / 1000;

			if (pFile->oldframe == -1)
				pFile->oldframe = newusec;
			

			if (newusec != pFile->oldframe) 
			{

				if (newusec < pFile->oldframe)
					ti = newusec + 1000 - pFile->oldframe;
				else
					ti = newusec - pFile->oldframe;
				//DPRINTK("[DEBUG: %d]     %lld    %d  %d     %d  ", __LINE__,(long long)tv.tv_sec*1000,newusec,ti,frame_ms);
				if ((ti != 0) && (pFile->frame_ms - ti > 0)) {
					ti = pFile->frame_ms - ti + 32;
				} else {
					ti = 15;
				}
				pFile->oldframe = newusec;
			}

			struct timeval delay;
			delay.tv_sec = 0;
			delay.tv_usec = ti * 1000; // 20 ms
//            select(0, NULL, NULL, NULL, &delay);

		}

	}else if(iReadSpeed == 0 )
	{
		if (av_read_frame(pFile->ic, &pFile->readpacket) < 0) 
		{		
			DPRINTK("av_read_frame err\n");
			return -1;
		}
	}else 
	{
		int iReadVideoFrameNum = 0;	
		int iSleepTime = 0;
		int ret;
		int64_t timestamp;
		int  time_sec;
		//快进时只读视频通道数据。
		AVRational * time_base = &pFile->ic->streams[0]->time_base;

	retry_read_frame:
		timestamp = av_q2d(*time_base) * pFile->now_file_dts;
		if( iReadSpeed > 0 )
			timestamp += 1;
		else
			timestamp -= 2;

		time_sec = (int)timestamp;

		if( time_sec < 0 )
		{
			DPRINTK("read over head,stop play\n");
			return -1;
		}

		DPRINTK("time %0.5g  time_sec:%d\n",timestamp,time_sec);

		ret = av_seek_frame(pFile->ic, -1 , time_sec * AV_TIME_BASE, AVSEEK_FLAG_ANY);
		if( ret < -1 )
		{		
			DPRINTK("av_seek_frame err\n");
			return -1;
		}	
		
		if (av_read_frame(pFile->ic, &pFile->readpacket) < 0) 
		{		
			DPRINTK("av_read_frame err\n");
			return -1;
		}

		iSleepTime = 1000000 / abs(iReadSpeed);	
		DPRINTK("iReadSpeed=%d  usleep(%d)\n",iReadSpeed,iSleepTime);
//        usleep(iSleepTime);

		if( (pFile->readpacket.flags & AV_PKT_FLAG_KEY) == 0 )
		{
			DPRINTK("no key frame ,need read next frame\n");
			pFile->now_file_dts = pFile->readpacket.dts;
			goto retry_read_frame;
		}
	/*	while(1)
		{
			if (av_read_frame(pFile->ic, &pFile->readpacket) < 0) 
			{		
				DPRINTK("av_read_frame err\n");
				return -1;
			}

			if( pFile->readpacket.size > 5 )
			{
				if( pFile->readpacke[0] == 0x0 && pFile->readpacke[1] == 0x0 && pFile->readpacke[2] == 0x0 && pFile->readpacke[3] == 0x1 )
				{
					if(pFile->readpacke[3] == 0x67)
					{
						int iSleepTime = 0;
						//读到下一个I 帧
						iSleepTime = pFile->frame_ms*iReadVideoFrameNum * 1000 / iReadSpeed;		
						DPRINTK("iReadSpeed=%d  usleep(%d)\n",iReadSpeed,iSleepTime);
						usleep(iSleepTime);
						break;
					}else
					{
						iReadVideoFrameNum++;
					}
				}
			}
		}*/
	}
		

	*iStreamIndex = pFile->readpacket.stream_index;

	// h264
	if( pFile->readpacket.stream_index== 0 && pFile->pVideoFilter )
	{
		int ret ;	
		
		ret = RF_filter_packet(pFile->ic,&pFile->readpacket,pFile->pVideoFilter);
		if( ret < 0 )
		{
			DPRINTK("RF_filter_packet err\n");
			return -1;
		}		
	}

	 //h265
	if( pFile->readpacket.stream_index== 0 && pFile->h265_vps_sps_pps_nalus_len > 0) 
	{
		int ret ;
		unsigned char * ptr = NULL;

		ptr = pFile->readpacket.data;

		ptr[0] = 0;
		ptr[1] = 0;
		ptr[2] = 0;
		ptr[3] = 1;			
		
		if( (pFile->readpacket.flags & AV_PKT_FLAG_KEY) != 0 )
		{
			if( pFile->h265_VideoBuf != NULL )
			{
//                Debug_Free(pFile->h265_VideoBuf);
                free(pFile->h265_VideoBuf);
				pFile->h265_VideoBuf = NULL;
			}

//            pFile->h265_VideoBuf = (unsigned char *)Debug_Malloc(pFile->h265_vps_sps_pps_nalus_len + pFile->readpacket.size );
            pFile->h265_VideoBuf = malloc(pFile->h265_vps_sps_pps_nalus_len + pFile->readpacket.size);

			memcpy(pFile->h265_VideoBuf,pFile->strH265_VPS_SPS_PPS_Nalu,pFile->h265_vps_sps_pps_nalus_len);
			memcpy(pFile->h265_VideoBuf + pFile->h265_vps_sps_pps_nalus_len,pFile->readpacket.data,pFile->readpacket.size);

			//DPRINTK("len=%d\n",pFile->h265_vps_sps_pps_nalus_len+pFile->readpacket.size);
			
		}
	}
	

	if( pFile->readpacket.stream_index == 1 && pFile->pAudioCode != NULL)
	{
		int  got_frame = 0;
		int ret = 0;		

		pFile->iAudioLen = 0;

		do 
		{
		        ret = avcodec_decode_audio4(pFile->pAudioCode, pFile->pAudioFrame, &got_frame, &pFile->readpacket);
		        if (ret < 0) 
			{
		            av_log(NULL, AV_LOG_ERROR, "Error decoding audio\n");
		           break;
		        }
		        pFile->readpacket.size -= ret;
		        pFile->readpacket.data += ret;

			 if (got_frame) 
			 {				
			 
		            /* if a frame has been decoded, output it */
		            int data_size = av_samples_get_buffer_size(NULL, pFile->pAudioCode->channels,
		                                                       pFile->pAudioFrame->nb_samples,
		                                                       pFile->pAudioCode->sample_fmt, 1);
		            if (data_size < 0) {
		                /* This should not occur, checking just for paranoia */
		                fprintf(stderr, "Failed to calculate data size\n");
           			  return -1;
		            }

				if( pFile->iAudioLen + data_size < AUDIO_BUF_SIZE)
				{		
					memcpy(pFile->strAudioBuf+pFile->iAudioLen,pFile->pAudioFrame->data[0],data_size);
					pFile->iAudioLen += data_size;
				}else
				{
					DPRINTK("audio buf is not enough  %d > %d\n",pFile->iAudioLen + data_size,AUDIO_BUF_SIZE);
				}
				
		        }
				
		}while(pFile->readpacket.size > 0);

		{			
			AVRational * time_base = &pFile->ic->streams[*iStreamIndex]->time_base;
			DPRINTK("stream[%d]  size=%d  pts=%lld dts=%lld  %d   time:%0.5g\n",pFile->readpacket.stream_index,
				pFile->readpacket.size,pFile->readpacket.pts,pFile->readpacket.dts,pFile->ic->streams[*iStreamIndex]->r_frame_rate.num,
				av_q2d(*time_base) * pFile->readpacket.dts);

			ConvertTime(pPlayTime,av_q2d(*time_base) * pFile->readpacket.dts);
			//DPRINTK("time stamp: %d-%d\n",pPlayTime->tv_sec,pPlayTime->tv_usec);
				
		}
		
		*pDataAddr = pFile->strAudioBuf;
		datasize = pFile->iAudioLen;
		return datasize;
		
	}
	
	datasize = pFile->readpacket.size;	


	if(pFile->readpacket.stream_index == 0)
	{
		char * pData = pFile->readpacket.data;

		if( (pFile->h265_vps_sps_pps_nalus_len > 0 ) &&  ( pFile->readpacket.flags & AV_PKT_FLAG_KEY != 0 )  )
		{
		}else
		{
			//DPRINTK("%x %x %x %x %x %x\n",pData[0],pData[1],pData[2],pData[3],pData[4],pData[5]);		
		}

		if( (pFile->readpacket.flags & AV_PKT_FLAG_KEY) != 0 )
			*isKeyFrame = 1;
		else
			*isKeyFrame = 0;
	}


	if(1)
	{			
			AVRational * time_base = &pFile->ic->streams[*iStreamIndex]->time_base;
			DPRINTK("stream[%d]  size=%d  pts=%lld dts=%lld  %d  isKeyFrame:%d  time:%0.5g\n",pFile->readpacket.stream_index,
				pFile->readpacket.size,pFile->readpacket.pts,pFile->readpacket.dts,pFile->ic->streams[*iStreamIndex]->r_frame_rate.num,*isKeyFrame,
				av_q2d(*time_base) * pFile->readpacket.dts);

			ConvertTime(pPlayTime,av_q2d(*time_base) * pFile->readpacket.dts);
			//DPRINTK("time stamp: %d-%d\n",pPlayTime->tv_sec,pPlayTime->tv_usec);
				
	}
	
	pFile->now_file_dts = pFile->readpacket.dts;


	if( pFile->readpacket.stream_index== 0 && pFile->h265_vps_sps_pps_nalus_len > 0) 
	{	
		if( (pFile->readpacket.flags & AV_PKT_FLAG_KEY) != 0 )
		{			
			*pDataAddr = pFile->h265_VideoBuf;			
			
			{
				char * pData = *pDataAddr;
				//DPRINTK("%x %x %x %x %x %x\n",pData[0],pData[1],pData[2],pData[3],pData[4],pData[5]);	
			}
			 return datasize + pFile->h265_vps_sps_pps_nalus_len;
		}
	}

	*pDataAddr = pFile->readpacket.data;
	
	return datasize;
}


int  RF_GetFileAllTime(void *FileHandle)
{
	FILE_PLAY * pFile = (FILE_PLAY *)FileHandle;	
	return pFile->allsecs;
}


int RF_JumpReadFile(void *FileHandle,int time,int iDdirection)
{
	FILE_PLAY * pFile = (FILE_PLAY *)FileHandle;
	int ret = 0;

	if( iDdirection >= 0 )
		ret = av_seek_frame(pFile->ic, -1 , time * AV_TIME_BASE, AVSEEK_FLAG_ANY);
	else
		ret = av_seek_frame(pFile->ic, -1 , time * AV_TIME_BASE, AVSEEK_FLAG_BACKWARD);
	
	return ret;
}


int RF_StopReadFile(void *FileHandle)
{
	FILE_PLAY * pFile = (FILE_PLAY *)FileHandle;

	if( pFile )
	{
		if( pFile->ic )
		  {		
		  	if( pFile->pVideoFilter )
		  	{
				 av_bitstream_filter_close(pFile->pVideoFilter); 
		  	}

			if(pFile->pAudioFrame )
			{
				av_frame_free(&pFile->pAudioFrame);
			}

			if( pFile->pAudioCode )
			{
				avcodec_close(pFile->pAudioCode);
			}
		       
		  	av_free_packet(&pFile->readpacket);
		  	avformat_close_input(&pFile->ic);
			if (pFile->ic != NULL) 
			{
				//av_read_pause(pFile->ic);				
				avformat_free_context(pFile->ic);
				pFile->ic = NULL;
			}
		   }

		if( pFile->h265_VideoBuf )
		{
//            Debug_Free(pFile->h265_VideoBuf);
            free(pFile->h265_VideoBuf);
		}

//        Debug_Free(pFile);
        free(pFile);
	}
	
	return 1;
}

int RF_PauseReadFile(void *FileHandle)
{
	FILE_PLAY * pFile = (FILE_PLAY *)FileHandle;
	return av_read_pause(pFile->ic);
}

int RF_ResumeReadFile(void *FileHandle)
{
	FILE_PLAY * pFile = (FILE_PLAY *)FileHandle;
	return av_read_play(pFile->ic);
}

typedef struct _AUDIO_SWR_
{
	 int init;
	 struct SwrContext *  swr;
	  int64_t src_ch_layout;
	  int64_t dst_ch_layout;
	  int src_rate;
	  int dst_rate;
	  enum AVSampleFormat src_sample_fmt;
	  enum AVSampleFormat dst_sample_fmt;
	   int src_nb_channels;
	   int dst_nb_channels;
	  int src_nb_samples;
	  int dst_nb_samples;
	  int max_dst_nb_samples;
	  uint8_t **src_data;
	  uint8_t **dst_data;
	  int src_linesize;
	  int dst_linesize;	 
}AUDIO_SWR;


AUDIO_SWR stSwrIn;
AUDIO_SWR stSwrOut;


int RF_InitAudioSwr(int src_audio_sampleRate)
{	
	int ret;
	memset(&stSwrIn,0x00,sizeof(stSwrIn));
	memset(&stSwrOut,0x00,sizeof(stSwrOut));

	DPRINTK("Init start! src_audio_sampleRate = %d\n",src_audio_sampleRate);
	

	 stSwrOut.swr  = swr_alloc();
	 if (!stSwrOut.swr) 
	 {
	     DPRINTK("Could not allocate swr_out resampler context\n");	  
	     goto err;
	 }

	 stSwrOut.dst_ch_layout = AV_CH_LAYOUT_MONO;
	 stSwrOut.src_ch_layout = AV_CH_LAYOUT_MONO;

	 stSwrOut.src_rate = 8000;
	 stSwrOut.dst_rate = src_audio_sampleRate;

	 stSwrOut.src_sample_fmt = AV_SAMPLE_FMT_S16;
	 stSwrOut.dst_sample_fmt = AV_SAMPLE_FMT_S16;
	 
	 stSwrOut.src_nb_samples = 160;

	  /* set options */
	 av_opt_set_int(stSwrOut.swr, "in_channel_layout",    stSwrOut.src_ch_layout, 0);
	 av_opt_set_int(stSwrOut.swr, "in_sample_rate",       stSwrOut.src_rate, 0);
	 av_opt_set_sample_fmt(stSwrOut.swr, "in_sample_fmt", stSwrOut.src_sample_fmt, 0);

	 av_opt_set_int(stSwrOut.swr, "out_channel_layout",     stSwrOut.dst_ch_layout, 0);
	 av_opt_set_int(stSwrOut.swr, "out_sample_rate",       stSwrOut.dst_rate, 0);
	 av_opt_set_sample_fmt(stSwrOut.swr, "out_sample_fmt", stSwrOut.dst_sample_fmt , 0);

	     /* initialize the resampling context */
	    if ((ret = swr_init(stSwrOut.swr)) < 0) 
	   {
	        DPRINTK("Failed to initialize the resampling context\n");
	        goto err;
	    }else
	    {
	    	stSwrOut.init = 1;
	    }		

		
	   /* allocate source and destination samples buffers */

	    stSwrOut.src_nb_channels = av_get_channel_layout_nb_channels(stSwrOut.src_ch_layout);
	    ret = av_samples_alloc_array_and_samples(&stSwrOut.src_data, &stSwrOut.src_linesize,  stSwrOut.src_nb_channels,
	                                             stSwrOut.src_nb_samples, stSwrOut.src_sample_fmt, 0);
	    if (ret < 0) 
	    {
	          DPRINTK("Could not allocate source samples\n");
	         goto err;
	    }

	    /* compute the number of converted samples: buffering is avoided
	     * ensuring that the output buffer will contain at least all the
	     * converted input samples */
	    stSwrOut.max_dst_nb_samples = stSwrOut.dst_nb_samples =
	        av_rescale_rnd(stSwrOut.src_nb_samples, stSwrOut.dst_rate, stSwrOut.src_rate, AV_ROUND_UP);

	    /* buffer is going to be directly written to a rawaudio file, no alignment */
	    stSwrOut.dst_nb_channels = av_get_channel_layout_nb_channels(stSwrOut.dst_ch_layout);
	    ret = av_samples_alloc_array_and_samples(&stSwrOut.dst_data, &stSwrOut.dst_linesize, stSwrOut.dst_nb_channels,
	                                             stSwrOut.dst_nb_samples, stSwrOut.dst_sample_fmt, 0);
	    if (ret < 0) 
	   {	       
	         DPRINTK("Could not allocate destination samples\n");
	         goto err;
	    }


		

	 stSwrIn.swr  = swr_alloc();
	 if (!stSwrIn.swr) 
	 {
	     DPRINTK("Could not allocate swr_inresampler context\n");	  
	     goto err;
	 }

	 stSwrIn.dst_ch_layout = AV_CH_LAYOUT_MONO;
	 stSwrIn.src_ch_layout = AV_CH_LAYOUT_MONO;

	 stSwrIn.src_rate = src_audio_sampleRate;
	 stSwrIn.dst_rate = 8000;

	 stSwrIn.src_sample_fmt = AV_SAMPLE_FMT_S16;
	 stSwrIn.dst_sample_fmt = AV_SAMPLE_FMT_S16;

	  stSwrIn.src_nb_samples = 160;

	  /* set options */
	 av_opt_set_int(stSwrIn.swr, "in_channel_layout",    stSwrIn.src_ch_layout, 0);
	 av_opt_set_int(stSwrIn.swr, "in_sample_rate",       stSwrIn.src_rate, 0);
	 av_opt_set_sample_fmt(stSwrIn.swr, "in_sample_fmt", stSwrIn.src_sample_fmt, 0);

	 av_opt_set_int(stSwrIn.swr, "out_channel_layout",     stSwrIn.dst_ch_layout, 0);
	 av_opt_set_int(stSwrIn.swr, "out_sample_rate",       stSwrIn.dst_rate, 0);
	 av_opt_set_sample_fmt(stSwrIn.swr, "out_sample_fmt", stSwrIn.dst_sample_fmt , 0);

	 /* initialize the resampling context */
	 if((ret = swr_init(stSwrIn.swr)) < 0) 
	 {
	     DPRINTK("Failed to initialize the resampling context\n");
	     goto err;
	 }else
	 {
	 	stSwrIn.init = 1;
	 }		

	   /* allocate source and destination samples buffers */

	    stSwrIn.src_nb_channels = av_get_channel_layout_nb_channels(stSwrIn.src_ch_layout);
	    ret = av_samples_alloc_array_and_samples(&stSwrIn.src_data, &stSwrIn.src_linesize,  stSwrIn.src_nb_channels,
	                                             stSwrIn.src_nb_samples, stSwrIn.src_sample_fmt, 0);
	    if (ret < 0) 
	    {
	          DPRINTK("Could not allocate source samples\n");
	         goto err;
	    }

	    /* compute the number of converted samples: buffering is avoided
	     * ensuring that the output buffer will contain at least all the
	     * converted input samples */
	    stSwrIn.max_dst_nb_samples = stSwrIn.dst_nb_samples =
	        av_rescale_rnd(stSwrIn.src_nb_samples, stSwrIn.dst_rate, stSwrIn.src_rate, AV_ROUND_UP);

	    /* buffer is going to be directly written to a rawaudio file, no alignment */
	    stSwrIn.dst_nb_channels = av_get_channel_layout_nb_channels(stSwrIn.dst_ch_layout);
	    ret = av_samples_alloc_array_and_samples(&stSwrIn.dst_data, &stSwrIn.dst_linesize, stSwrIn.dst_nb_channels,
	                                             stSwrIn.dst_nb_samples, stSwrIn.dst_sample_fmt, 0);
	    if (ret < 0) 
	   {	       
	         DPRINTK("Could not allocate destination samples\n");
	         goto err;
	    }


	 DPRINTK("Init ok!\n");

	return 1;
err:
	return -1;
}


int RF_ConvertAudioOut(char * src_buf,int src_len,char * dest_buf,int * dest_len)
{
	int ret;
	int dst_bufsize;

	if( stSwrOut.init == 0 )
	{
		DPRINTK("stSwrOut not init!\n");
		goto err;
	}
	
	memcpy(stSwrOut.src_data[0],src_buf, stSwrOut.src_nb_samples*2);

	 /* compute destination number of samples */
        stSwrOut.dst_nb_samples = av_rescale_rnd(swr_get_delay(stSwrOut.swr, stSwrOut.src_rate) +
                                        stSwrOut.src_nb_samples, stSwrOut.dst_rate, stSwrOut.src_rate, AV_ROUND_UP);
        if (stSwrOut.dst_nb_samples > stSwrOut.max_dst_nb_samples) {
            av_freep(&stSwrOut.dst_data[0]);
            ret = av_samples_alloc(stSwrOut.dst_data, &stSwrOut.dst_linesize, stSwrOut.dst_nb_channels,
                                   stSwrOut.dst_nb_samples, stSwrOut.dst_sample_fmt, 1);
            if (ret < 0)
               goto err;

	    DPRINTK("alloc %d\n",stSwrOut.dst_nb_samples);
            stSwrOut.max_dst_nb_samples = stSwrOut.dst_nb_samples;
        }

        /* convert to destination format */
        ret = swr_convert(stSwrOut.swr, stSwrOut.dst_data, stSwrOut.dst_nb_samples, (const uint8_t **)stSwrOut.src_data, stSwrOut.src_nb_samples);
        if (ret < 0) 
	{
            DPRINTK("Error while converting\n");
            goto err;
        }
		
        dst_bufsize = av_samples_get_buffer_size(&stSwrOut.dst_linesize, stSwrOut.dst_nb_channels, ret, stSwrOut.dst_sample_fmt, 1);
        if (dst_bufsize < 0) 
	{
            DPRINTK("Could not get sample buffer size\n");
             goto err;
        }

	memcpy(dest_buf,stSwrOut.dst_data[0],dst_bufsize);

	*dest_len = dst_bufsize;

	return 1;
err:
	return -1;
}

int RF_ConvertAudio(AUDIO_SWR * pSwr,char * src_buf,int src_len,char * dest_buf,int * dest_len)
{
	int ret;
	int dst_bufsize;

	if( pSwr->init == 0 )
	{
		DPRINTK("stSwrOut not init!\n");
		goto err;
	}
	
	memcpy(pSwr->src_data[0],src_buf, pSwr->src_nb_samples*2);

	 /* compute destination number of samples */
        pSwr->dst_nb_samples = av_rescale_rnd(swr_get_delay(pSwr->swr, pSwr->src_rate) +
                                        pSwr->src_nb_samples, pSwr->dst_rate, pSwr->src_rate, AV_ROUND_UP);
        if (pSwr->dst_nb_samples > pSwr->max_dst_nb_samples) {
            av_freep(&pSwr->dst_data[0]);
            ret = av_samples_alloc(pSwr->dst_data, &pSwr->dst_linesize, pSwr->dst_nb_channels,
                                   pSwr->dst_nb_samples, pSwr->dst_sample_fmt, 1);
            if (ret < 0)
               goto err;

	    DPRINTK("alloc %d\n",pSwr->dst_nb_samples);
            pSwr->max_dst_nb_samples = pSwr->dst_nb_samples;
        }

        /* convert to destination format */
        ret = swr_convert(pSwr->swr, pSwr->dst_data, pSwr->dst_nb_samples, (const uint8_t **)pSwr->src_data, pSwr->src_nb_samples);
        if (ret < 0) 
	{
            DPRINTK("Error while converting\n");
            goto err;
        }
		
        dst_bufsize = av_samples_get_buffer_size(&pSwr->dst_linesize, pSwr->dst_nb_channels, ret, pSwr->dst_sample_fmt, 1);
        if (dst_bufsize < 0) 
	{
            DPRINTK("Could not get sample buffer size\n");
             goto err;
        }

	memcpy(dest_buf,pSwr->dst_data[0],dst_bufsize);

	*dest_len = dst_bufsize;

	return 1;
err:
	return -1;
}


int RJONE_ConvertAudioOut(char * src_buf,int src_len,char * dest_buf,int * dest_len)
{
	return RF_ConvertAudio(&stSwrOut,src_buf,src_len,dest_buf,dest_len);
}




int RJONE_ConvertAudioIn(char * src_buf,int src_len,char * dest_buf,int * dest_len)
{
	return RF_ConvertAudio(&stSwrIn,src_buf,src_len,dest_buf,dest_len);
}

#endif

