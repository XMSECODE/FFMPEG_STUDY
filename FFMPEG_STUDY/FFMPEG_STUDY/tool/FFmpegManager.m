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

@interface FFmpegManager ()

@property(nonatomic,assign)BOOL ffmpegIsInit;

@property(nonatomic,assign)BOOL ffmpegNetIsInit;


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
        [self initFFMPEGNET];
    }
    return self;
}

- (void)openURL:(NSString *)urlString videoSuccess:(void(^)(AVFrame *frame))videoSuccess audioSuccess:(void(^)(AVFrame *frame))audioSuccess failure:(void(^)(NSError *error))failure {
    
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
    
    while (av_read_frame(formatContext, packet) >= 0) {
        {
            if(packet->stream_index == videoStreamID) {
//                printf("video\n");
                avcodec_send_packet(videoCodecContext, packet);
                result = avcodec_receive_frame(videoCodecContext, videoFrame);
                switch (result) {
                    case 0:{
                        videoSuccess(videoFrame);
                    }
                        break;
                        
                    case AVERROR_EOF:
                        printf("the decoder has been fully flushed,\
                               and there will be no more output frames.\n");
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
            if (packet->stream_index == audioStreamID) {
//                printf("audio\n");
                avcodec_send_packet(audioCodeContext, packet);
                result = avcodec_receive_frame(audioCodeContext, audioFrame);
                switch (result) {
                    case 0:{
                        audioSuccess(audioFrame);
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
    av_free(videoFrame);
    av_frame_free(&audioFrame);
    avcodec_close(videoCodecContext);
    avcodec_close(audioCodeContext);
    avformat_close_input(&formatContext);
}

#pragma mark - 初始化组件
- (void)initFFMPEG {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        av_register_all();
    });
}

#pragma mark - 初始化网络组件
- (void)initFFMPEGNET {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        avformat_network_init();
    });
}

@end
