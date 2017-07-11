//
//  FFmpegManager.m
//  FFMPEG_STUDY
//
//  Created by xiangmingsheng on 2017/6/25.
//  Copyright © 2017年 XMSECODE. All rights reserved.
//

#import "FFmpegManager.h"
#import "avcodec.h"
#import "Header.h"
#import <AVFoundation/AVFoundation.h>

@interface FFmpegManager ()

@property(nonatomic,copy)NSString* URLString;

@property(nonatomic,strong)AVAudioPlayer* play1;

@property(nonatomic,strong)NSMutableArray* play2array;


@end

static FFmpegManager *staticFFmpegManager;

@implementation FFmpegManager

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        staticFFmpegManager = [[FFmpegManager alloc] init];
    });
    return staticFFmpegManager;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [self initFFMPEG];
    }
    return self;
}

- (void)initFFMPEG {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        av_register_all();
        avformat_network_init();
    });
}

#pragma mark - Public
- (void)getFirstVideoFrameWithURL:(NSString *)urlString success:(void(^)(AVFrame *firstFrame))success failure:(void(^)(NSError *error))failure {
    [self openURL:urlString videoSuccess:success audioSuccess:nil failure:failure isGetFirstVideoFrame:YES];
}

- (void)openAudioURL:(NSString *)urlString audioSuccess:(void(^)(AVFrame *frame))audioSuccess failure:(void(^)(NSError *error))failure {
    [self openURL:urlString videoSuccess:nil audioSuccess:audioSuccess failure:failure isGetFirstVideoFrame:NO];
}

int flush_encoder(AVFormatContext *fmt_ctx,unsigned int stream_index){
    int ret;
    int got_frame;
    AVPacket enc_pkt;
    if (!(fmt_ctx->streams[stream_index]->codec->codec->capabilities &
          CODEC_CAP_DELAY))
        return 0;
    while (1) {
        enc_pkt.data = NULL;
        enc_pkt.size = 0;
        av_init_packet(&enc_pkt);
        ret = avcodec_encode_audio2 (fmt_ctx->streams[stream_index]->codec, &enc_pkt,
                                     NULL, &got_frame);
        av_frame_free(NULL);
        if (ret < 0)
            break;
        if (!got_frame){
            ret=0;
            break;
        }
        printf("Flush Encoder: Succeed to encode 1 frame!\tsize:%5d\n",enc_pkt.size);
        /* mux encoded frame */
        ret = av_write_frame(fmt_ctx, &enc_pkt);
        if (ret < 0)
            break;
    }
    return ret;  
}

- (void)getPCMDataAudioURL:(NSString *)urlString audioSuccess:(void(^)(NSData *PCMData))audioSuccess failure:(void(^)(NSError *error))failure {
    {
        {
            AVFormatContext* pFormatCtx;
            AVOutputFormat* fmt;
            AVStream* audio_st;
            AVCodecContext* pCodecCtx;
            AVCodec* pCodec;
            
            uint8_t* frame_buf;
            AVFrame* pFrame;
            AVPacket pkt;
            
            int got_frame=0;
            int ret=0;
            int size=0;
            
            FILE *in_file=NULL;                         //Raw PCM data
            int framenum=1000;                          //Audio frame number
            const char* out_file = "/Users/xiangmingsheng/Music/网易云音乐/tdjm.aac";          //Output URL
            int i;
            
            in_file= fopen("/Users/xiangmingsheng/Music/网易云音乐/Bridge - 雾都历.mp3", "rb");
            
            av_register_all();
            
            //Method 1.
            pFormatCtx = avformat_alloc_context();
            fmt = av_guess_format(NULL, out_file, NULL);
            pFormatCtx->oformat = fmt;
            
            
            //Method 2.
            //avformat_alloc_output_context2(&pFormatCtx, NULL, NULL, out_file);
            //fmt = pFormatCtx->oformat;
            
            //Open output URL
            if (avio_open(&pFormatCtx->pb,out_file, AVIO_FLAG_READ_WRITE) < 0){
                printf("Failed to open output file!\n");
                return ;
            }
            
            {
                self.URLString = urlString;
                
                AVFormatContext *formatContext = NULL;
                AVInputFormat *inputFormat = NULL;
                AVDictionary *avDictionary = NULL;
                const char *url = [urlString cStringUsingEncoding:NSUTF8StringEncoding];
                int result = avformat_open_input(&formatContext, url, inputFormat, &avDictionary);
                if (result != 0) {
                    NSError *error = [NSError EC_errorWithLocalizedDescription:@"open url failure,please check url is available"];
                    failure(error);
                    return;
                }
                
                result = avformat_find_stream_info(formatContext, NULL);
                if (result < 0) {
                    NSError *error = [NSError EC_errorWithLocalizedDescription:@"find stream info failure"];
                    failure(error);
                    return;
                }
                
                //打印信息
                av_dump_format(formatContext, 0, url, 0);
            }
            
       

            
            audio_st = avformat_new_stream(pFormatCtx, 0);
            if (audio_st==NULL){
                return ;
            }
            
            pCodecCtx = audio_st->codec;
            pCodecCtx->codec_id = fmt->audio_codec;
            pCodecCtx->codec_type = AVMEDIA_TYPE_AUDIO;
            pCodecCtx->sample_fmt = AV_SAMPLE_FMT_S16;
            pCodecCtx->sample_rate= 44100;
            pCodecCtx->channel_layout=AV_CH_LAYOUT_STEREO;
            pCodecCtx->channels = av_get_channel_layout_nb_channels(pCodecCtx->channel_layout);
            pCodecCtx->bit_rate = 64000;
            
            //Show some information
            av_dump_format(pFormatCtx, 0, out_file, 1);
            
            pCodec = avcodec_find_encoder(pCodecCtx->codec_id);
            if (!pCodec){
                printf("Can not find encoder!\n");
                return ;
            }
            if (avcodec_open2(pCodecCtx, pCodec,NULL) < 0){
                printf("Failed to open encoder!\n");
                return ;
            }
            pFrame = av_frame_alloc();
            pFrame->nb_samples= pCodecCtx->frame_size;
            pFrame->format= pCodecCtx->sample_fmt;
            
            size = av_samples_get_buffer_size(NULL, pCodecCtx->channels,pCodecCtx->frame_size,pCodecCtx->sample_fmt, 1);
            frame_buf = (uint8_t *)av_malloc(size);
            avcodec_fill_audio_frame(pFrame, pCodecCtx->channels, pCodecCtx->sample_fmt,(const uint8_t*)frame_buf, size, 1);
            
            //Write Header
            avformat_write_header(pFormatCtx,NULL);
            
            av_new_packet(&pkt,size);
            
            for (i=0; i<framenum; i++){
                //Read PCM
                if (fread(frame_buf, 1, size, in_file) <= 0){
                    printf("Failed to read raw data! \n");
                    return ;
                }else if(feof(in_file)){
                    break;
                }
                pFrame->data[0] = frame_buf;  //PCM Data
                
                pFrame->pts=i*100;
                got_frame=0;
                //Encode
                ret = avcodec_encode_audio2(pCodecCtx, &pkt,pFrame, &got_frame);
                if(ret < 0){
                    printf("Failed to encode!\n");
                    return ;
                }  
                if (got_frame==1){  
                    printf("Succeed to encode 1 frame! \tsize:%5d\n",pkt.size);  
                    pkt.stream_index = audio_st->index;  
                    ret = av_write_frame(pFormatCtx, &pkt);  
                    av_free_packet(&pkt);  
                }  
            }  
            
            //Flush Encoder  
            ret = flush_encoder(pFormatCtx,0);  
            if (ret < 0) {  
                printf("Flushing encoder failed\n");  
                return ;
            }  
            
            //Write Trailer  
            av_write_trailer(pFormatCtx);  
            
            //Clean  
            if (audio_st){  
                avcodec_close(audio_st->codec);  
                av_free(pFrame);  
                av_free(frame_buf);  
            }  
            avio_close(pFormatCtx->pb);  
            avformat_free_context(pFormatCtx);  
            
            fclose(in_file);  
            
            return ;  
        }
    }
    
    
    
    
    
    
    return;
    
    self.URLString = urlString;
    
    AVFormatContext *formatContext = NULL;
    AVInputFormat *inputFormat = NULL;
    AVDictionary *avDictionary = NULL;
    const char *url = [urlString cStringUsingEncoding:NSUTF8StringEncoding];
    int result = avformat_open_input(&formatContext, url, inputFormat, &avDictionary);
    if (result != 0) {
        NSError *error = [NSError EC_errorWithLocalizedDescription:@"open url failure,please check url is available"];
        failure(error);
        return;
    }
    
    result = avformat_find_stream_info(formatContext, NULL);
    if (result < 0) {
        NSError *error = [NSError EC_errorWithLocalizedDescription:@"find stream info failure"];
        failure(error);
        return;
    }
    
    //打印信息
    av_dump_format(formatContext, 0, url, 0);

    //查找音频流
    int audioStreamID = -1;
    for (int i = 0; i < formatContext->nb_streams; i++) {
        if (formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            audioStreamID = i;
            break;
        }
    }
    
    FILE *in_file=NULL;                         //Raw PCM data
    int framenum=1000;                          //Audio frame number
    const char* out_file = "tdjm.aac";          //Output URL
    int i;
    
    printf("==================\n");
    printf("the first audio stream index is : %d\n", audioStreamID);
    
    printf("==================\n");
    
    AVCodecParameters *audioCodecParameters = formatContext->streams[audioStreamID]->codecpar;
    AVStream *audioStream = formatContext->streams[audioStreamID];
    printf("codec Par :%d,format %d\n",audioCodecParameters->frame_size,audioCodecParameters->format);
    
    AVCodec *audioCodec = avcodec_find_decoder(audioStream->codecpar->codec_id);
    AVCodecContext *audioCodeContext = avcodec_alloc_context3(audioCodec);
    
    if ((result = avcodec_parameters_to_context(audioCodeContext, audioStream->codecpar)) < 0) {
        printf("copy the codec parameters to context fail, err code : %d\n", result);
        NSError *error = [NSError EC_errorWithLocalizedDescription:[NSString stringWithFormat:@"copy the codec parameters to context fail, err code : %d\n",result]];
        failure(error);
        return;
    }
    
    if ((result = avcodec_open2(audioCodeContext, audioCodec, NULL)) < 0) {
        printf("open codec fail , err code : %d", result);
        NSError *error = [NSError EC_errorWithLocalizedDescription:[NSString stringWithFormat:@"open codec fail , err code : %d", result]];
        failure(error);
        return;
    }
    
    AVOutputFormat *outputFormat = av_guess_format("adts", "adts", "adts");
    formatContext->oformat = outputFormat;
    
//        avio_open(formatContext->pb, "", <#int flags#>)
    
    
    result = avformat_write_header(formatContext, NULL);
    if (result == AVSTREAM_INIT_IN_WRITE_HEADER) {
        printf("AVSTREAM_INIT_IN_WRITE_HEADER");
    }else if (result == AVSTREAM_INIT_IN_INIT_OUTPUT) {
        printf("AVSTREAM_INIT_IN_INIT_OUTPUT");
    }else if (result < 0) {
        printf("write header failure");
        NSError *error = [NSError EC_errorWithLocalizedDescription:@"write header failure"];
        failure(error);
        return;
    }
    
    AVPacket *packet = av_packet_alloc();
    
    AVFrame *audioFrame = av_frame_alloc();
    
    while (av_read_frame(formatContext, packet) >= 0) {
        
        {
            if (packet->stream_index == audioStreamID && audioSuccess) {
                //                printf("audio\n");
                avcodec_send_packet(audioCodeContext, packet);
                result = avcodec_receive_frame(audioCodeContext, audioFrame);
                switch (result) {
                    case 0:{
                        
                        NSData *data = [NSData dataWithBytes:audioFrame->data[0] length:audioFrame->linesize[0]];
                        
                        
                        
                        
                        audioSuccess(data);
                    }
                        break;
                        
                    case AVERROR_EOF:
                        printf("the decoder has been fully flushed,\
                               and there will be no more output frames.\n");
                        break;
                        
                    case AVERROR(EAGAIN):
                        printf("audio Resource temporarily unavailable\n");
                        break;
                        
                    case AVERROR(EINVAL):
                        printf("Invalid argument\n");
                        break;
                    default:
                        break;
                }
                av_packet_unref(packet);
            }
        }
    }
    printf("decode end!");
    av_frame_free(&audioFrame);
    avcodec_close(audioCodeContext);
    avformat_close_input(&formatContext);
}

- (void)openVideoURL:(NSString *)urlString videoSuccess:(void(^)(AVFrame *frame))videoSuccess failure:(void(^)(NSError *error))failure {
    [self openURL:urlString videoSuccess:videoSuccess audioSuccess:nil failure:failure isGetFirstVideoFrame:NO];
}

- (void)openURL:(NSString *)urlString videoSuccess:(void(^)(AVFrame *frame))videoSuccess audioSuccess:(void(^)(AVFrame *frame))audioSuccess failure:(void(^)(NSError *error))failure {
    [self openURL:urlString videoSuccess:videoSuccess audioSuccess:audioSuccess failure:failure isGetFirstVideoFrame:NO];
}

#pragma mark - Private
- (void)openURL:(NSString *)urlString videoSuccess:(void(^)(AVFrame *frame))videoSuccess audioSuccess:(void(^)(AVFrame *frame))audioSuccess failure:(void(^)(NSError *error))failure isGetFirstVideoFrame:(BOOL)isGetFirstVideoFrame{
    
    self.URLString = urlString;
    
    AVFormatContext *formatContext = NULL;
    AVInputFormat *inputFormat = NULL;
    AVDictionary *avDictionary = NULL;
    const char *url = [urlString cStringUsingEncoding:NSUTF8StringEncoding];
    int result = avformat_open_input(&formatContext, url, inputFormat, &avDictionary);
    if (result != 0) {
        NSError *error = [NSError EC_errorWithLocalizedDescription:@"open url failure,please check url is available"];
        failure(error);
        return;
    }
    
    result = avformat_find_stream_info(formatContext, NULL);
    if (result < 0) {
        NSError *error = [NSError EC_errorWithLocalizedDescription:@"find stream info failure"];
        failure(error);
        return;
    }
    
    //打印信息
    av_dump_format(formatContext, 0, url, 0);
    
    //查找视频流
    int videoStreamID = -1;
    for (int i = 0; i < formatContext->nb_streams; i++) {
        if (formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoStreamID = i;
            break;
        }
    }
    //查找音频流
    int audioStreamID = -1;
    for (int i = 0; i < formatContext->nb_streams; i++) {
        if (formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            audioStreamID = i;
            break;
        }
    }
    
    printf("==================\n");
    printf("the first video stream index is : %d\n", videoStreamID);
    printf("the first audio stream index is : %d\n", audioStreamID);
    
    
    AVCodecParameters *codecParameters = formatContext->streams[videoStreamID]->codecpar;
    AVStream *videoStream = formatContext->streams[videoStreamID];
    
    printf("==================\n");
    printf("codec Par :%d   %d, format %d\n", codecParameters->width,codecParameters->height, codecParameters->format);
    
    AVCodecParameters *audioCodecParameters = formatContext->streams[audioStreamID]->codecpar;
    AVStream *audioStream = formatContext->streams[audioStreamID];
    printf("codec Par :%d,format %d\n",audioCodecParameters->frame_size,audioCodecParameters->format);
    //  AV_SAMPLE_FMT_FLTP
    
    AVCodec *Videocodec = avcodec_find_decoder(videoStream->codecpar->codec_id);
    AVCodecContext *videoCodecContext = avcodec_alloc_context3(Videocodec);
    
    AVCodec *audioCodec = avcodec_find_decoder(audioStream->codecpar->codec_id);
    AVCodecContext *audioCodeContext = avcodec_alloc_context3(audioCodec);
    
    if((result = avcodec_parameters_to_context(videoCodecContext, videoStream->codecpar)) < 0) {
        printf("copy the codec parameters to context fail, err code : %d\n", result);
        NSError *error = [NSError EC_errorWithLocalizedDescription:[NSString stringWithFormat:@"copy the codec parameters to context fail, err code : %d\n", result]];
        failure(error);
        return;
    }
    if ((result = avcodec_parameters_to_context(audioCodeContext, audioStream->codecpar)) < 0) {
        printf("copy the codec parameters to context fail, err code : %d\n", result);
        NSError *error = [NSError EC_errorWithLocalizedDescription:[NSString stringWithFormat:@"copy the codec parameters to context fail, err code : %d\n",result]];
        failure(error);
        return;
    }
    
    if((result = avcodec_open2(videoCodecContext, Videocodec, NULL)) < 0) {
        printf("open codec fail , err code : %d", result);
        NSError *error = [NSError EC_errorWithLocalizedDescription:[NSString stringWithFormat:@"open codec fail , err code : %d", result]];
        failure(error);
        return;
    }
    
    if ((result = avcodec_open2(audioCodeContext, audioCodec, NULL)) < 0) {
        printf("open codec fail , err code : %d", result);
        NSError *error = [NSError EC_errorWithLocalizedDescription:[NSString stringWithFormat:@"open codec fail , err code : %d", result]];
        failure(error);
        return;
    }
    
    AVPacket *packet = av_packet_alloc();
    AVFrame *videoFrame = av_frame_alloc();
    
    
    AVFrame *audioFrame = av_frame_alloc();
    
    BOOL getFirstVideoFrame = NO;
    int i = 0;
    
    while (av_read_frame(formatContext, packet) >= 0) {
        {
            if(packet->stream_index == videoStreamID && videoSuccess) {
                
//                printf("video\n");
                avcodec_send_packet(videoCodecContext, packet);
                result = avcodec_receive_frame(videoCodecContext, videoFrame);
                switch (result) {
                    case 0:{
                        videoSuccess(videoFrame);
                        getFirstVideoFrame = YES;
                    }
                        break;
                        
                    case AVERROR_EOF:
                        printf("video the decoder has been fully flushed, and there will be no more output frames.\n");
                        break;
                        
                    case AVERROR(EAGAIN):
                        printf("Resource temporarily unavailable\n");
                        break;
                        
                    case AVERROR(EINVAL):
                        printf("Invalid argument\n");
                        break;
                    default:
                        break;
                }
                av_packet_unref(packet);
                
            }
        }
        {
            if (packet->stream_index == audioStreamID && audioSuccess) {
//                printf("audio\n");
                avcodec_send_packet(audioCodeContext, packet);
                NSData *data = [NSData dataWithBytes:packet->data length:packet->size];
                
                NSError *error ;
                AVAudioPlayer *audiopalyer = [[AVAudioPlayer alloc] initWithData:data error:&error];
                if (error == nil) {
//                    NSLog(@"play");
                    [NSThread sleepForTimeInterval:0.02];
                    [audiopalyer play];
                    NSLog(@"%lf",audiopalyer.duration);
                    if (self.play2array == nil) {
                        self.play2array = [NSMutableArray array];
                    }
                    [self.play2array addObject:audiopalyer];
                }else {
                    NSLog(@"error ========= %@",error);
                }
                
                if (i == 3) {
                    data = [NSData dataWithContentsOfFile:@"/Users/xiangmingsheng/Music/网易云音乐/Bridge - 雾都历.mp3"];
                    audiopalyer = [[AVAudioPlayer alloc] initWithData:data error:&error];
                    self.play1 = audiopalyer;
                    if (error == nil) {
                        NSLoffg(@"play");
//                        [audiopalyer play];
                    }else {
                        NSLog(@"error ========= %@",error);
                    }
                }
                
                NSString *filePath = [NSString stringWithFormat:@"/Users/xiangmingsheng/Desktop/未命名文件夹/ss%d.mp3",i];
//                [data writeToFile:filePath atomically:YES];
                result = avcodec_receive_frame(audioCodeContext, audioFrame);
                switch (result) {
                    case 0:{
                     
                        audioSuccess(audioFrame);
                    }
                        break;
                        
                    case AVERROR_EOF:
                        printf("audio the decoder has been fully flushed, and there will be no more output frames.\n");
                        break;
                        
                    case AVERROR(EAGAIN):
                        printf("audio Resource temporarily unavailable\n");
                        break;
                        
                    case AVERROR(EINVAL):
                        printf("Invalid argument\n");
                        break;
                    default:
                        break;
                }
                av_packet_unref(packet);
            }
        }
        i++;
        if (isGetFirstVideoFrame) {
            if (getFirstVideoFrame == YES) {
                break;
            }
        }
    }
    printf("decode end!");
    av_free(videoFrame);
    av_frame_free(&audioFrame);
    avcodec_close(videoCodecContext);
    avcodec_close(audioCodeContext);
    avformat_close_input(&formatContext);
}

@end
