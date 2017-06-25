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
#import "imgutils.h"
#import "opt.h"
#import "Header.h"

#import "ECSwsscaleManager.h"

#define FRAMECOUNT 50000

const char *imagePath = "file:///Users/xiangmingsheng/Downloads/ss";


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *showImageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    @"rtmp://live.hkstv.hk.lxdns.com/live/hks" 香港播放地址
    
    
    NSLog(@"开始");
    [self initFFMPEG];
    [self initFFMPEGNET];
    
    
    __weak __typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//                [weakSelf loadFFMpegWithURL:@"file:///Users/xiangmingsheng/Downloads/QQ20170613-085300-HD.mp4"];
        [weakSelf loadFFMpegWithURL:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
    });
    
    
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
                        @autoreleasepool {
                            UIImage *image = [ECSwsscaleManager getImageFromAVFrame:frame];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                self.showImageView.image = image;
                                static dispatch_once_t onceToken;
                                dispatch_once(&onceToken, ^{
                                    int scale = [UIScreen mainScreen].scale;
                                    self.showImageView.W = image.size.width / scale;
                                    self.showImageView.H = image.size.height / scale;
                                });
                            });
                        }
                        
//
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

@end
