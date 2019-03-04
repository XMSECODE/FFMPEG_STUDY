//
//  FFmpegManager.m
//  FFMPEG_STUDY
//
//  Created by xiangmingsheng on 2017/6/25.
//  Copyright © 2017年 XMSECODE. All rights reserved.
//

#import "ESCFFmpegFileTool.h"
#import "avcodec.h"
#import "Header.h"
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, FFPlayState) {
    FFPlayStatePrepare,
    FFPlayStatePlaying,
    FFPlayStateStop,
};

@interface ESCFFmpegFileTool ()

@property(nonatomic,copy)NSString* URLString;

@property(nonatomic,assign)AVCodecContext *videoCodecContext;

@property(nonatomic,assign)AVCodecContext *audioCodeContext;

@property(nonatomic,assign)AVFormatContext *formatContext;

@property(nonatomic,assign)NSInteger videoStreamID;

@property(nonatomic,assign)NSInteger audioStreamID;

@property(nonatomic,assign)BOOL isGetFirstVideoFrame;

@property(nonatomic,copy)void(^readVideoPacketSuccess)(ESCFrameDataModel *model);

@property(nonatomic,copy)void(^readAudioPacketSuccess)(ESCFrameDataModel *model);

@property(nonatomic,copy)void(^decodeVideoPacketSuccess)(ESCFrameDataModel *model);

@property(nonatomic,copy)void(^decodeAudioPacketSuccess)(ESCFrameDataModel *model);

@property(nonatomic,copy)void(^decodeEnd)(void);

@property(nonatomic,assign)FFPlayState playState;

@property(nonatomic,strong)ESCSwsscaleTool* swsscaleManager;

@end

@implementation ESCFFmpegFileTool

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
        avcodec_register_all();
        avformat_network_init();
    });
}

- (void)dealloc {
    NSLog(@"%@====%s",self,__FUNCTION__);
}

#pragma mark - Public
- (void)openURL:(NSString *)urlString
        success:(void(^)(ESCMediaInfoModel *infoModel))success
        failure:(void(^)(NSError *error))failure{
    
    self.playState = FFPlayStatePrepare;
    
    self.URLString = urlString;
    ESCMediaInfoModel *mediaInfoModel = [[ESCMediaInfoModel alloc] init];
    
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
    
    
    AVCodecParameters *videoParameters = _formatContext->streams[videoStreamID]->codecpar;
    AVStream *videoStream = _formatContext->streams[videoStreamID];
    printf("==================\n");
    printf("codec Par :%d   %d, format %d\n", videoParameters->width,videoParameters->height, videoParameters->format);
    AVRational videoRational = videoStream->avg_frame_rate;
    mediaInfoModel.videoFrameRate = videoRational.num;
    mediaInfoModel.videoWidth = videoParameters->width;
    mediaInfoModel.videoHeight = videoParameters->height;
    
    AVCodecParameters *audioCodecParameters = _formatContext->streams[audioStreamID]->codecpar;
    AVStream *audioStream = _formatContext->streams[audioStreamID];
    printf("codec Par :%d,format %d\n",audioCodecParameters->frame_size,audioCodecParameters->format);
    printf("--codec_type--%d\n--codec_id--%d\n--format--%d\n--bit_rate--%lld\n--sample_rate--%d\n--channel_layout--%llu\n--channels--%d\n---frame_size-%d\n",
           audioCodecParameters->codec_type,
           audioCodecParameters->codec_id,
           audioCodecParameters->format,
           audioCodecParameters->bit_rate,
           audioCodecParameters->sample_rate,
           audioCodecParameters->channel_layout,
           audioCodecParameters->channels,
           audioCodecParameters->frame_size);
    printf("==================\n");
    
    
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
    
    self.videoStreamID = videoStreamID;
    self.audioStreamID = audioStreamID;
    
    self.playState = FFPlayStatePlaying;
    success(mediaInfoModel);
}

- (void)readPacketVideoSuccess:(void(^)(ESCFrameDataModel *model))videoSuccess
                  audioSuccess:(void(^)(ESCFrameDataModel *model))audioSuccess
                       failure:(void(^)(NSError *error))failure
                     decodeEnd:(void(^)(void))decodeEnd {
    self.readVideoPacketSuccess = videoSuccess;
    self.readAudioPacketSuccess = audioSuccess;
    [self readMediaData];
}

- (void)decodePacket:(ESCFrameDataModel *)model
      outPixelFormat:(ESCPixelFormat)pixelFormat
        videoSuccess:(void(^)(ESCFrameDataModel *model))videoSuccess
        audioSuccess:(void(^)(ESCFrameDataModel *model))audioSuccess
             failure:(void(^)(NSError *error))failure {
    self.decodeVideoPacketSuccess = videoSuccess;
    self.decodeAudioPacketSuccess = audioSuccess;
    
    enum AVPixelFormat outFormat;
    if (pixelFormat == ESCPixelFormatYUV420) {
        outFormat = AV_PIX_FMT_YUV420P;
    }else {
        outFormat = AV_PIX_FMT_RGB24;
    }
    
    int result = 0;
    
    if(model.packet->stream_index == self.videoStreamID && self.decodeVideoPacketSuccess) {
        result = avcodec_send_packet(_videoCodecContext, model.packet);
        AVFrame *videoFrame = av_frame_alloc();
        result = avcodec_receive_frame(_videoCodecContext, videoFrame);
            switch (result) {
                case 0:{
                    AVFrame *resultFrame;
                    if (videoFrame->format != outFormat) {
                        if (self.swsscaleManager == nil) {
                            self.swsscaleManager = [[ESCSwsscaleTool alloc] init];
                            [self.swsscaleManager setupWithAVFrame:videoFrame outFormat:pixelFormat];
                        }
                        resultFrame = [self.swsscaleManager getAVFrame:videoFrame];
                        resultFrame->format = outFormat;
                    }else {
                        resultFrame = videoFrame;
                    }
                    ESCFrameDataModel *videoModel = [[ESCFrameDataModel alloc] init];
                    videoModel.frame = resultFrame;
                    videoModel.type = ESCFrameDataModelTypeVideoFrame;
                    self.decodeVideoPacketSuccess(videoModel);
                    av_frame_free(&videoFrame);
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
        }else if (model.packet->stream_index == self.audioStreamID && self.decodeAudioPacketSuccess) {
            result = avcodec_send_packet(_audioCodeContext, model.packet);
            int i = 0;
            while (1) {
                AVFrame *audioFrame = av_frame_alloc();
                result = avcodec_receive_frame(_audioCodeContext, audioFrame);
                switch (result) {
                    case 0:{
                        i++;
                        ESCFrameDataModel *audioModel = [[ESCFrameDataModel alloc] init];
                        audioModel.frame = audioFrame;
                        audioModel.type = ESCFrameDataModelTypeAudioFrame;
                        self.decodeAudioPacketSuccess(audioModel);
                        av_frame_free(&audioFrame);
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
        }
    AVPacket *packet = model.packet;
    av_packet_unref(model.packet);
    av_packet_free(&packet);
}

- (void)freeModelArray:(NSArray <ESCFrameDataModel *>*)modelArray {
    for (ESCFrameDataModel *model in modelArray) {
        if (model.type == ESCFrameDataModelTypeAudioPacket || model.type == ESCFrameDataModelTypeVideoPacket) {
            AVPacket *packet = model.packet;
            av_packet_unref(model.packet);
            av_packet_free(&packet);
        }else {
            AVFrame *frame = model.frame;
            av_frame_unref(frame);
            av_frame_free(&frame);
        }
    }
}

- (void)stop {
    self.playState = FFPlayStateStop;
    
    avcodec_close(_videoCodecContext);
    avcodec_close(_audioCodeContext);
    avformat_close_input(&_formatContext);
    [self.swsscaleManager destroy];
    printf("play stop!\n");
    if (self.decodeEnd) {
        self.decodeEnd();
    }
}

#pragma mark - Private
- (void)readMediaData {
    int result = 0;
    AVPacket *packet = av_packet_alloc();
    result = av_read_frame(_formatContext, packet);
    if (result >= 0) {
        ESCFrameDataModel *model = [[ESCFrameDataModel alloc] init];
        if(packet->stream_index == self.videoStreamID && self.readVideoPacketSuccess) {
            model.packet = packet;
            model.type = ESCFrameDataModelTypeVideoPacket;
            self.readVideoPacketSuccess(model);
        }else if (packet->stream_index == self.audioStreamID && self.readAudioPacketSuccess) {
            model.packet = packet;
            model.type = ESCFrameDataModelTypeAudioPacket;
            self.readAudioPacketSuccess(model);
        }
    }else {
        NSLog(@"读取数据失败");
    }
}

@end
