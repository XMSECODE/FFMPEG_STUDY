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

#define FRAMECOUNT 5000
const char *filepath = "/Users/shiming/ffmpegResearch/FFmpeg-Tutorial/ss1-part.mp4";
const char *imagePath = "file:///Users/xiangmingsheng/Downloads/ss";


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"开始");
    [self initFFMPEG];
    [self loadFFMpegWithLocalFile:@"file:///Users/xiangmingsheng/Downloads/QQ20170613-085300-HD.mp4"];

}

- (void)loadFFMpegWithLocalFile:(NSString *)localFilePath {
    int errCode = 0;
    
    AVFormatContext *formatContext = NULL;
    AVInputFormat *inputFormat = NULL;
    AVDictionary *avDictionary = NULL;
    
    const char *url = [localFilePath cStringUsingEncoding:NSUTF8StringEncoding];
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
        NSLog(@"读取信息成功==%d",result);
    }
    //打印文件信息
    av_dump_format(formatContext, 0, url, 0);
    
    int i;
    int videoStreamID = -1;
    for ( i = 0; i < formatContext->nb_streams; ++i) {
        if(formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoStreamID = i;
            break;
        }
    }
    
    printf("==================\n");
    printf("the first video stream index is : %d\n", videoStreamID);
    
    AVCodecParameters *pCodecPar = formatContext->streams[videoStreamID]->codecpar;
    AVStream *pStream= formatContext->streams[videoStreamID];
    
    printf("==================\n");
    printf("codec Par :%d   %d, format %d\n", pCodecPar->width,pCodecPar->height, pCodecPar->format);
    
    AVCodec *pCodec = avcodec_find_decoder(pStream->codecpar->codec_id);
    AVCodecContext *pCodecCtx = avcodec_alloc_context3(pCodec);
    
    if((errCode = avcodec_parameters_to_context(pCodecCtx, pStream->codecpar)) < 0) {
        printf("copy the codec parameters to context fail, err code : %d\n", errCode);
        return;
    }
    if((errCode = avcodec_open2(pCodecCtx, pCodec, NULL)) < 0) {
        printf("open codec fail , err code : %d", errCode);
    }
    
    AVPacket *packet = av_packet_alloc();
    AVFrame *frame = av_frame_alloc();
    AVFrame *frameRGB = av_frame_alloc();
    
    while (av_read_frame(formatContext, packet) >= 0) {
        if(packet->stream_index == videoStreamID) {
            avcodec_send_packet(pCodecCtx, packet);
            errCode = avcodec_receive_frame(pCodecCtx, frame);
            switch (errCode) {
                case 0://成功
                    printf("got a frame !\n");
                    if (i++ < FRAMECOUNT) {
//                        saveFrame(frame, pCodecPar->width,pCodecPar->height, pCodecPar->format, i);
                        struct SwsContext *pSwsCtx = sws_alloc_context();
                        sws_scale(pSwsCtx, frame->data, frame->linesize, 0,pCodecCtx->height, frameRGB->data, frameRGB->linesize);
                        saveImg(frame, pCodecPar->width, pCodecPar->height, i);
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
    avcodec_close(pCodecCtx);
    avformat_close_input(&formatContext);
    
}

- (void)initFFMPEG {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        av_register_all();
    });
}

- (void)saveImageWith:(AVFrame *)frame width:(int)width height:(int)height frmae:(int)iFrame {
    saveImg(frame, width, height, iFrame);
}

//需要转化为rgb的数据才可以存储
void saveImg(AVFrame *pFrame, int width, int height, int iFrame) {
    FILE *pFile;
    
    int  y;
    
    NSString *fileStr = [NSString stringWithFormat:@"/Users/xiangmingsheng/Downloads/ss/%d.ppm",iFrame];
    char *szFilename = [fileStr cStringUsingEncoding:NSUTF8StringEncoding];
//    NSLog(@"%@",fileStr);
    // Open file
//    sprintf(szFilename, "frame%d.ppm", iFrame);
    pFile=fopen(szFilename, "w");
    if(pFile==NULL) {
        NSLog(@"写入失败");
        return;
    }
    // Write header
    fprintf(pFile, "P6\n%d %d\n255\n", width, height);
    
    // Write pixel data
    for(y=0; y<height; y++) {
        fwrite(pFrame->data[0]+y*pFrame->linesize[0],  width*3,1, pFile);
    }
    // Close file
    fclose(pFile);
}

void saveFrame(AVFrame * pFrame, int width, int height, int format,int iFrame) {
    FILE *pFile;
    NSString *fileStr = [NSString stringWithFormat:@"/Users/xiangmingsheng/Downloads/ss/%d.ppm",iFrame];
    char *szFilename = [fileStr cStringUsingEncoding:NSUTF8StringEncoding];
    int  y;
    
    
    // Open file
//    sprintf(szFilename, "frameout%d.yuv", iFrame);
    pFile=fopen(szFilename, "ab");
    if(pFile==NULL)
        return;
    
    // Write pixel data
    for(y=0; y<height ; y++)
        fwrite(pFrame->data[0]+y*pFrame->linesize[0], 1, width, pFile);
    for(y=0; y<height / 2; y++) {
        fwrite(pFrame->data[1]+y*pFrame->linesize[1], 1, width / 2, pFile);
    }
    for(y=0; y<height / 2; y++) {
        fwrite(pFrame->data[2]+y*pFrame->linesize[2], 1, width / 2, pFile);
    }
//     Close file
    fclose(pFile);
}

@end



