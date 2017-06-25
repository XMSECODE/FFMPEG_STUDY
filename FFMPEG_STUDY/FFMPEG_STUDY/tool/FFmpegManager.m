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

- (void)openURL:(NSString *)urlString success:(void(^)(AVFrame *frame))success failure:(void(^)(NSError *error))failure {
    
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
    
    printf("==================\n");
    printf("the first video stream index is : %d\n", videoStreamID);
    
    AVCodecParameters *codecParameters = formatContext->streams[videoStreamID]->codecpar;
    AVStream *stream = formatContext->streams[videoStreamID];
    
    printf("==================\n");
    printf("codec Par :%d   %d, format %d\n", codecParameters->width,codecParameters->height, codecParameters->format);
    
    AVCodec *codec = avcodec_find_decoder(stream->codecpar->codec_id);
    AVCodecContext *codecContext = avcodec_alloc_context3(codec);
    
    if((result = avcodec_parameters_to_context(codecContext, stream->codecpar)) < 0) {
        printf("copy the codec parameters to context fail, err code : %d\n", result);
        NSError *error = [NSError EC_errorWithLocalizedDescription:[NSString stringWithFormat:@"copy the codec parameters to context fail, err code : %d\n", result]];
        failure(error);
        return;
    }
    if((result = avcodec_open2(codecContext, codec, NULL)) < 0) {
        printf("open codec fail , err code : %d", result);
        NSError *error = [NSError EC_errorWithLocalizedDescription:[NSString stringWithFormat:@"open codec fail , err code : %d", result]];
        failure(error);
        return;
    }
    
    AVPacket *packet = av_packet_alloc();
    AVFrame *frame = av_frame_alloc();
    
    while (av_read_frame(formatContext, packet) >= 0) {
        if(packet->stream_index == videoStreamID) {
            avcodec_send_packet(codecContext, packet);
            result = avcodec_receive_frame(codecContext, frame);
            switch (result) {
                case 0:{
                    success(frame);
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
        }
        av_packet_unref(packet);
    }
    av_free(frame);
    avcodec_close(codecContext);
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
