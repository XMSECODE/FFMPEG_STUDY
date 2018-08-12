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
#import "record_format.h"
#import "rjone.h"

@interface FFmpegManager ()

@property(nonatomic,copy)NSString* URLString;


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
- (void)getFirstVideoFrameWithURL:(NSString *)urlString
                          success:(void(^)(AVFrame *firstFrame))success
                          failure:(void(^)(NSError *error))failure
                        decodeEnd:(void(^)(void))decodeEnd {
    [self openURL:urlString videoSuccess:success audioSuccess:nil failure:failure isGetFirstVideoFrame:YES decodeEnd:decodeEnd];
}

- (void)openAudioURL:(NSString *)urlString
        audioSuccess:(void(^)(AVFrame *frame))audioSuccess
             failure:(void(^)(NSError *error))failure
           decodeEnd:(void(^)(void))decodeEnd {
    [self openURL:urlString videoSuccess:nil audioSuccess:audioSuccess failure:failure isGetFirstVideoFrame:NO decodeEnd:decodeEnd];
}

- (void)openVideoURL:(NSString *)urlString
        videoSuccess:(void(^)(AVFrame *frame))videoSuccess
             failure:(void(^)(NSError *error))failure
           decodeEnd:(void(^)(void))decodeEnd {
    [self openURL:urlString videoSuccess:videoSuccess audioSuccess:nil failure:failure isGetFirstVideoFrame:NO decodeEnd:decodeEnd];
}

- (void)openURL:(NSString *)urlString
   videoSuccess:(void(^)(AVFrame *frame))videoSuccess
   audioSuccess:(void(^)(AVFrame *frame))audioSuccess
        failure:(void(^)(NSError *error))failure
      decodeEnd:(void(^)(void))decodeEnd {
    [self openURL:urlString videoSuccess:videoSuccess audioSuccess:audioSuccess failure:failure isGetFirstVideoFrame:NO decodeEnd:decodeEnd];
}

- (void)stop {
    
}

#pragma mark - Private
- (void)openURL:(NSString *)urlString videoSuccess:(void(^)(AVFrame *frame))videoSuccess audioSuccess:(void(^)(AVFrame *frame))audioSuccess failure:(void(^)(NSError *error))failure isGetFirstVideoFrame:(BOOL)isGetFirstVideoFrame decodeEnd:(void(^)(void))decodeEnd{
    
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
    {
        if (audioStream->codecpar->format == AV_SAMPLE_FMT_FLTP) {
            printf("para    ");
        }
        AVCodecParameters *para = audioStream->codecpar;
        printf("--codec_type--%d\n--codec_id--%d\n--format--%d\n--bit_rate--%lld\n--sample_rate--%d\n--channel_layout--%llu\n--channels--%d\n---frame_size-%d\n",
               para->codec_type,
               para->codec_id,
               para->format,
               para->bit_rate,
               para->sample_rate,
               para->channel_layout,
               para->channels,
               para->frame_size);

    }
    
    if ((result = avcodec_parameters_to_context(audioCodeContext, audioStream->codecpar)) < 0) {
        printf("copy the codec parameters to context fail, err code : %d\n", result);
        NSError *error = [NSError EC_errorWithLocalizedDescription:[NSString stringWithFormat:@"copy the codec parameters to context fail, err code : %d\n",result]];
        failure(error);
        return;
    }
    
//    printf("para    ");
//    AVCodecParameters *para = audioStream->codecpar;
//    printf("%d---%d---%d---%zd---%d---%zd---%d\n",para->codec_type,para->codec_id,para->format,para->bit_rate,para->sample_rate,para->channel_layout,para->channels);
//    
    
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
    RECORD_FORAMT_STREAM_INFO pVideoStream;
    pVideoStream.codec_id = CODECID_V_H264;
    pVideoStream.video_framerate = 25;
    pVideoStream.video_width = codecParameters->width;
    pVideoStream.video_height = codecParameters->height;
//    Handle handle = RF_CreateRecordFile("ff.mp4", &pVideoStream, NULL);
    
    AVFormatContext *context;
    avformat_alloc_output_context2(&context, NULL, NULL, "ff.mp4");
    
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
                int i = 0;
                while (1) {
                    result = avcodec_receive_frame(audioCodeContext, audioFrame);
                    switch (result) {
                        case 0:{
                            i++;
//                            printf("%d==%d\n",i,audioCodeContext->frame_number);
                            audioSuccess(audioFrame);
                        }
                            break;
                            
                        case AVERROR_EOF:
//                            printf("audio the decoder has been fully flushed, and there will be no more output frames.\n");
                            break;
                            
                        case AVERROR(EAGAIN):
//                            printf("audio Resource temporarily unavailable\n");
                            break;
                            
                        case AVERROR(EINVAL):
//                            printf("Invalid argument\n");
                            break;
                        default:
                            break;
                    }
                    if (result != 0) {
                        break;
                    }
                }
                
                av_packet_unref(packet);
            }
        }
        if (isGetFirstVideoFrame) {
            if (getFirstVideoFrame == YES) {
                break;
            }
        }
    }
    printf("decode end!");
    decodeEnd();
    av_free(videoFrame);
    av_frame_free(&audioFrame);
    avcodec_close(videoCodecContext);
    avcodec_close(audioCodeContext);
    avformat_close_input(&formatContext);
}

@end
