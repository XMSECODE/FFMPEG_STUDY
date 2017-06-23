//
//  ViewController.m
//  FFMPEG_STUDY
//
//  Created by xiangmingsheng on 2017/6/15.
//  Copyright © 2017年 XMSECODE. All rights reserved.
//

#import "ViewController.h"
#import "avformat.h"
#import "avcodec.h"
#import "swscale.h"
#import "OpenGLView20.h"

#define FRAMECOUNT 50000
const char *filepath = "/Users/shiming/ffmpegResearch/FFmpeg-Tutorial/ss1-part.mp4";
const char *imagePath = "file:///Users/xiangmingsheng/Downloads/ss";


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    @"rtmp://live.hkstv.hk.lxdns.com/live/hks" 香港播放地址
    
    
    NSLog(@"开始");
    [self initFFMPEG];
    [self initFFMPEGNET];
    
    //    [self loadFFMpegWithLocalFile:@"file:///Users/xiangmingsheng/Downloads/QQ20170613-085300-HD.mp4"];
    [self loadFFMpegWithURL:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
    
    
}

#pragma mark - 读取文件
- (void)loadFFMpegWithURL:(NSString *)urlString {
    
    AVFormatContext *formatContext = NULL;
    AVInputFormat *inputFormat = NULL;
    AVDictionary *avDictionary = NULL;
    const char *url = [urlString cStringUsingEncoding:NSUTF8StringEncoding];
    int result = avformat_open_input(&formatContext, url, inputFormat, &avDictionary);
    if (result != 0) {
        NSLog(@"打开失败");
        return;
    }else {
        NSLog(@"打开成功");
    }
    
    result = avformat_find_stream_info(formatContext, NULL);
    if (result < 0) {
        NSLog(@"读取信息失败==%d",result);
        return;
    }else {
        NSLog(@"读取信息成功");
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
        return;
    }
    if((result = avcodec_open2(codecContext, codec, NULL)) < 0) {
        printf("open codec fail , err code : %d", result);
        return;
    }
    
    AVPacket *packet = av_packet_alloc();
    AVFrame *frame = av_frame_alloc();
    
    int i = 0;
    
    while (av_read_frame(formatContext, packet) >= 0) {
        if(packet->stream_index == videoStreamID) {
            avcodec_send_packet(codecContext, packet);
            result = avcodec_receive_frame(codecContext, frame);
            switch (result) {
                case 0://成功
                    printf("got a frame !\n");
                    if (i < FRAMECOUNT) {
                        [self saveImageWith:frame width:codecParameters->width height:codecParameters->height frmae:i];
                        i++;

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
    
    NSLog(@"结束");
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

- (void)saveImageWith:(AVFrame *)frame width:(int)width height:(int)height frmae:(int)iFrame {
    FILE *pFile;
    
    NSString *fileStr = [NSString stringWithFormat:@"/Users/xiangmingsheng/Downloads/ss/%d.ppm",iFrame];
    const char *szFilename = [fileStr cStringUsingEncoding:NSUTF8StringEncoding];
    
    pFile=fopen(szFilename, "w");
    if(pFile==NULL) {
        NSLog(@"打开文件失败");
        printf("%s\n",szFilename);
        return;
    }
    
    if (frame->format == 0) {
        printf("format  :   AV_PIX_FMT_YUV420P\n");
    }
    printf("数据类型：%d\n",frame->format);
    
    
//    img_convert_ctx = sws_getContext(pCodecCtx->width, pCodecCtx->height, pCodecCtx->pix_fmt, pCodecCtx->width, pCodecCtx->height, PIX_FMT_RGB24, SWS_BICUBIC, NULL, NULL, NULL);
    
//    sws_scale(img_convert_ctx, (const uint8_t* const*)pFrame->data, pFrame->linesize, 0, pCodecCtx->height, pFrameYUV->data, pFrameYUV->linesize);
//    fwrite(pFrameYUV->data[0],(pCodecCtx->width)*(pCodecCtx->height)*3,1,output);
    
    struct SwsContext *swsContext = sws_getContext(frame->width, frame->height, AV_PIX_FMT_YUV420P, frame->width, frame->height, AV_PIX_FMT_RGB24, SWS_BICUBIC, NULL, NULL, NULL);
    
    AVFrame *RGBFrame = av_frame_alloc();
    
    int result_height = sws_scale(swsContext, (const uint8_t* const*)frame->data, frame->linesize, 0, frame->height, RGBFrame->data, RGBFrame->linesize);
    if (result_height == 0) {
        printf("result_height == 0\n");
        fclose(pFile);
        return;
    }
    printf("result_height = %d",result_height);
    
    fwrite(RGBFrame->data[0], RGBFrame->width * RGBFrame->height * 3, 1, pFile);
    
    
    // Write header AVPixelFormat
    fprintf(pFile, "P6\n%d %d\n255\n", width, height);
    
    // Write pixel data
    for(int y=0; y<height; y++) {
        
//        printf("%zd\n",frame->data[0]);
        
//        printf("%d\n",y * frame->linesize[0]);
    
//        printf(" %p ",frame->data[0] + y * frame->linesize[0]);
        
//        fwrite(frame->data[0]+y*frame->linesize[0],  1,width * 3, pFile);
    }
    
    //write frame
//    for(y=0; y<height ; y++)
//        fwrite(frame->data[0]+y*frame->linesize[0], 1, width, pFile);
//    for(y=0; y<height / 2; y++) {
//        fwrite(frame->data[1]+y*frame->linesize[1], 1, width / 2, pFile);
//    }
//    for(y=0; y<height / 2; y++) {
//        fwrite(frame->data[2]+y*frame->linesize[2], 1, width / 2, pFile);
//    }
    
    
    // Close file
    fclose(pFile);
}


@end



