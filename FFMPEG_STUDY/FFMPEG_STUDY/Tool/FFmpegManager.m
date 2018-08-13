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

typedef NS_ENUM(NSUInteger, FFPlayState) {
    FFPlayStatePrepare,
    FFPlayStatePlaying,
    FFPlayStateStop,
};

@interface FFmpegManager ()

@property(nonatomic,copy)NSString* URLString;

@property(nonatomic,strong)NSOperationQueue* playOperationQueue;

@property(nonatomic,assign)AVCodecContext *videoCodecContext;

@property(nonatomic,assign)AVCodecContext *audioCodeContext;

@property(nonatomic,assign)AVFormatContext *formatContext;

@property(nonatomic,assign)AVFrame *videoFrame;

@property(nonatomic,assign)AVFrame *audioFrame;

@property(nonatomic,assign)AVPacket *packet;

@property(nonatomic,assign)NSInteger videoStreamID;

@property(nonatomic,assign)NSInteger audioStreamID;

@property(nonatomic,assign)BOOL isGetFirstVideoFrame;

@property(nonatomic,copy)void(^videoSuccess)(AVFrame *frame,AVPacket *packet);

@property(nonatomic,copy)void(^audioSuccess)(AVFrame *frame,AVPacket *packet);

@property(nonatomic,copy)void(^decodeEnd)(void);

@property(nonatomic,weak)NSTimer* playTime;

@property(nonatomic,assign)FFPlayState playState;

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
    self.playOperationQueue = [[NSOperationQueue alloc] init];
    self.playOperationQueue.maxConcurrentOperationCount = 1;
}

#pragma mark - Public
- (void)getFirstVideoFrameWithURL:(NSString *)urlString
                          success:(void(^)(AVFrame *firstFrame))success
                          failure:(void(^)(NSError *error))failure
                        decodeEnd:(void(^)(void))decodeEnd {
    [self openURL:urlString videoSuccess:^(AVFrame *frame, AVPacket *packet) {
        success(frame);
    } audioSuccess:nil failure:failure decodeEnd:decodeEnd];
}

- (void)openAudioURL:(NSString *)urlString
        audioSuccess:(void(^)(AVFrame *frame,AVPacket *packet))audioSuccess
             failure:(void(^)(NSError *error))failure
           decodeEnd:(void(^)(void))decodeEnd {
    [self openURL:urlString videoSuccess:nil audioSuccess:audioSuccess failure:failure isGetFirstVideoFrame:NO decodeEnd:decodeEnd];
}

- (void)openVideoURL:(NSString *)urlString
        videoSuccess:(void(^)(AVFrame *frame,AVPacket *packet))videoSuccess
             failure:(void(^)(NSError *error))failure
           decodeEnd:(void(^)(void))decodeEnd {
    [self openURL:urlString videoSuccess:videoSuccess audioSuccess:nil failure:failure isGetFirstVideoFrame:NO decodeEnd:decodeEnd];
}

- (void)openURL:(NSString *)urlString
   videoSuccess:(void(^)(AVFrame *frame,AVPacket *packet))videoSuccess
   audioSuccess:(void(^)(AVFrame *frame,AVPacket *packet))audioSuccess
        failure:(void(^)(NSError *error))failure
      decodeEnd:(void(^)(void))decodeEnd {
    [self openURL:urlString videoSuccess:videoSuccess audioSuccess:audioSuccess failure:failure isGetFirstVideoFrame:NO decodeEnd:decodeEnd];
}

- (void)stop {
    
    [self.playOperationQueue cancelAllOperations];
    
    [self.playOperationQueue addOperationWithBlock:^{
        if (self.playTime) {
            [self.playTime invalidate];
        }
        self.playState = FFPlayStateStop;
        av_frame_free(&_videoFrame);
        av_frame_free(&_audioFrame);
        av_packet_free(&_packet);
        avcodec_close(_videoCodecContext);
        avcodec_close(_audioCodeContext);
        avformat_close_input(&_formatContext);
        
        printf("play stop!");
        if (self.decodeEnd) {
            self.decodeEnd();
        }
    }];
}

#pragma mark - Private
- (void)openURL:(NSString *)urlString
   videoSuccess:(void(^)(AVFrame *frame,AVPacket *packet))videoSuccess
   audioSuccess:(void(^)(AVFrame *frame,AVPacket *packet))audioSuccess
        failure:(void(^)(NSError *error))failure
isGetFirstVideoFrame:(BOOL)isGetFirstVideoFrame
      decodeEnd:(void(^)(void))decodeEnd{
    
    self.playState = FFPlayStatePrepare;
    
    self.URLString = urlString;
    
    
    AVInputFormat *inputFormat = NULL;
    AVDictionary *avDictionary = NULL;
    
    const char *url = [urlString cStringUsingEncoding:NSUTF8StringEncoding];
    int result = avformat_open_input(&_formatContext, url, inputFormat, &avDictionary);
    if (result != 0) {
        NSError *error = [NSError EC_errorWithLocalizedDescription:@"open url failure,please check url is available"];
        failure(error);
        return;
    }
    
    result = avformat_find_stream_info(_formatContext, NULL);
    if (result < 0) {
        NSError *error = [NSError EC_errorWithLocalizedDescription:@"find stream info failure"];
        failure(error);
        return;
    }
    
    //打印信息
    av_dump_format(_formatContext, 0, url, 0);
    
    //查找视频流
    int videoStreamID = -1;
    for (int i = 0; i < _formatContext->nb_streams; i++) {
        if (_formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoStreamID = i;
            break;
        }
    }
    //查找音频流
    int audioStreamID = -1;
    for (int i = 0; i < _formatContext->nb_streams; i++) {
        if (_formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
            audioStreamID = i;
            break;
        }
    }
    
    printf("==================\n");
    printf("the first video stream index is : %d\n", videoStreamID);
    printf("the first audio stream index is : %d\n", audioStreamID);
    
    
    AVCodecParameters *codecParameters = _formatContext->streams[videoStreamID]->codecpar;
    AVStream *videoStream = _formatContext->streams[videoStreamID];
    
    printf("==================\n");
    printf("codec Par :%d   %d, format %d\n", codecParameters->width,codecParameters->height, codecParameters->format);
    
    AVCodecParameters *audioCodecParameters = _formatContext->streams[audioStreamID]->codecpar;
    AVStream *audioStream = _formatContext->streams[audioStreamID];
    printf("codec Par :%d,format %d\n",audioCodecParameters->frame_size,audioCodecParameters->format);
    //  AV_SAMPLE_FMT_FLTP
    
    AVCodec *Videocodec = avcodec_find_decoder(videoStream->codecpar->codec_id);
    _videoCodecContext = avcodec_alloc_context3(Videocodec);
    
    AVCodec *audioCodec = avcodec_find_decoder(audioStream->codecpar->codec_id);
    _audioCodeContext = avcodec_alloc_context3(audioCodec);
    
    if((result = avcodec_parameters_to_context(_videoCodecContext, videoStream->codecpar)) < 0) {
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
    
    if ((result = avcodec_parameters_to_context(_audioCodeContext, audioStream->codecpar)) < 0) {
        printf("copy the codec parameters to context fail, err code : %d\n", result);
        NSError *error = [NSError EC_errorWithLocalizedDescription:[NSString stringWithFormat:@"copy the codec parameters to context fail, err code : %d\n",result]];
        failure(error);
        return;
    }
    
//    printf("para    ");
//    AVCodecParameters *para = audioStream->codecpar;
//    printf("%d---%d---%d---%zd---%d---%zd---%d\n",para->codec_type,para->codec_id,para->format,para->bit_rate,para->sample_rate,para->channel_layout,para->channels);
//    
    
    if((result = avcodec_open2(_videoCodecContext, Videocodec, NULL)) < 0) {
        printf("open codec fail , err code : %d", result);
        NSError *error = [NSError EC_errorWithLocalizedDescription:[NSString stringWithFormat:@"open codec fail , err code : %d", result]];
        failure(error);
        return;
    }
    
    if ((result = avcodec_open2(_audioCodeContext, audioCodec, NULL)) < 0) {
        printf("open codec fail , err code : %d", result);
        NSError *error = [NSError EC_errorWithLocalizedDescription:[NSString stringWithFormat:@"open codec fail , err code : %d", result]];
        failure(error);
        return;
    }
    
    self.audioSuccess = audioSuccess;
    self.videoSuccess = videoSuccess;
    self.decodeEnd = decodeEnd;
    
    self.videoStreamID = videoStreamID;
    self.audioStreamID = audioStreamID;
    
    _videoFrame = av_frame_alloc();
    _audioFrame = av_frame_alloc();
    _packet = av_packet_alloc();

    
    self.playTime = [NSTimer scheduledTimerWithTimeInterval:1.0 / 60.0 target:self selector:@selector(readMediaDataInPlayQueue) userInfo:nil repeats:YES];
    
    self.playState = FFPlayStatePlaying;
    
    [[NSRunLoop currentRunLoop] run];
}

- (void)readMediaDataInPlayQueue {
    printf("prepare read data\n");
    if (self.playOperationQueue && self.playOperationQueue.operationCount <= 2) {
        [self.playOperationQueue addOperationWithBlock:^{
            if (self.playState == FFPlayStatePlaying) {
                [self readMediaData];
            }else {
                printf("play stoped!!!");
            }
        }];
    }
}

- (void)readMediaData {
    
    printf("read data\n");
    BOOL getFirstVideoFrame = NO;
    
    
    int result = 0;
    
    while (av_read_frame(_formatContext, _packet) >= 0) {
        {
            if(_packet->stream_index == self.videoStreamID && self.videoSuccess) {
                
                
                //                printf("video\n");
                avcodec_send_packet(_videoCodecContext, _packet);
                result = avcodec_receive_frame(_videoCodecContext, _videoFrame);
                switch (result) {
                    case 0:{
                        self.videoSuccess(_videoFrame,_packet);
                        getFirstVideoFrame = YES;
                        printf("read video data success!\n");
                        return;
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
                av_packet_unref(_packet);
            }
        }
        {
            if (_packet->stream_index == self.audioStreamID && self.audioSuccess) {
                //                printf("audio\n");
                avcodec_send_packet(_audioCodeContext, _packet);
                int i = 0;
                while (1) {
                    result = avcodec_receive_frame(_audioCodeContext, _audioFrame);
                    switch (result) {
                        case 0:{
                            i++;
                            //                            printf("%d==%d\n",i,audioCodeContext->frame_number);
                            self.audioSuccess(_audioFrame,_packet);
//                            printf("read audio data success!\n");
//                            return;
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
                
                av_packet_unref(_packet);
            }
        }
        if (self.isGetFirstVideoFrame) {
            if (getFirstVideoFrame == YES) {
                break;
            }
        }
    }
    printf("read data failue!\n");
}

@end
