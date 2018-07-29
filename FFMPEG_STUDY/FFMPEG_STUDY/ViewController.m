//
//  ViewController.m
//  FFMPEG_STUDY
//
//  Created by xiangmingsheng on 2017/6/15.
//  Copyright © 2017年 XMSECODE. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "avformat.h"
#import "avcodec.h"
#import "swscale.h"
#import "imgutils.h"
#import "opt.h"
#import "Header.h"
#import "ESCAACToPCMDecoder.h"
#import "ESCAudioStreamPlayer.h"

#import "ECSwsscaleManager.h"
#import "FFmpegManager.h"
#import "FFmpegRemuxer.h"
#import "ESCOpenGLESView.h"

@interface ViewController (){
    FILE * file;
}

@property (weak, nonatomic) IBOutlet UIImageView *showImageView;

@property(nonatomic,strong)NSFileHandle* audioFileHandle;

@property(nonatomic,assign)NSInteger writeAudioDataFrameCount;

@property(nonatomic,strong)ESCAudioStreamPlayer* audioPlayer;

@property(nonatomic,weak)ESCOpenGLESView* openGLESView;

@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    
//    ESCOpenGLESView *openglesView = [[ESCOpenGLESView alloc] initWithFrame:CGRectMake(0, 50 + 200 , 200 , 200)];
//    self.openGLESView = openglesView;
//    self.openGLESView.type = ESCVideoDataTypeYUV420;
//    [self.view addSubview:openglesView];
//
//    NSString * path = [[NSBundle mainBundle] pathForResource:@"file" ofType:@"yuv"];
//
//    file = fopen(path.UTF8String, "r");
    
    [self playHKTV];
//    [self draw];
}

//- (void)draw {
//    if (feof(file)) {
//        return;
//    }
//    size_t yuv_length = 176*144*3/2;
//    Byte buf[yuv_length];
//    fread(buf, 1, yuv_length, file);
//    NSLog(@"%@",[NSData dataWithBytes:buf length:yuv_length]);
////    [self.playView displayYUVI420Data:buf width:176 height:144];
//
//
////    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width, height, GL_LUMINANCE, GL_UNSIGNED_BYTE, data);
////    //U在Y之后，长度等于点数的1/4，即宽高的积的1/4。
////    glBindTexture(GL_TEXTURE_2D, _texture_YUV[1]);
////    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width/2, height/2, GL_LUMINANCE, GL_UNSIGNED_BYTE, data + width * height);
////    //V在U之后，长度等于点数的1/4，即宽高的积的1/4。
////    glBindTexture(GL_TEXTURE_2D, _texture_YUV[2]);
////    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width/2, height/2, GL_LUMINANCE, GL_UNSIGNED_BYTE, data + width * height * 5 / 4);
//
//
//    NSData *ydata = [NSData dataWithBytes:buf length:176 * 144];
//    NSData *udata = [NSData dataWithBytes:buf+ 176 * 144 length:176 * 144 / 4];
//    NSData *vdata = [NSData dataWithBytes:buf + 176 * 144 * 5 / 4 length:176 * 144 / 4];
//    //            NSLog(@"%d==%d==%d",ydata.length,udata.length,vdata.length);
//    [self.openGLESView loadYUV420PDataWithYData:ydata uData:udata vData:vdata width:176 height:144];
//
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self draw];
//    });
//}
- (void)playHKTV {
    NSString *hongkongTVPath = @"rtmp://live.hkstv.hk.lxdns.com/live/hks";
    
    self.audioPlayer = [[ESCAudioStreamPlayer alloc] initWithSampleRate:48000 formatID:kAudioFormatLinearPCM formatFlags:kAudioFormatFlagIsSignedInteger   channelsPerFrame:2 bitsPerChannel:32 framesPerPacket:1];
    
    [self playWithImageViewWithURLString:hongkongTVPath];
}

- (void)playLocalVideoFile {
    NSString *mp4DemoPath = [[NSBundle mainBundle] pathForResource:@"demo.mp4" ofType:nil];
    
    self.audioPlayer = [[ESCAudioStreamPlayer alloc] initWithSampleRate:8000 formatID:kAudioFormatLinearPCM formatFlags:kAudioFormatFlagIsFloat  channelsPerFrame:1 bitsPerChannel:32 framesPerPacket:1];
    
    [self playWithImageViewWithURLString:mp4DemoPath];
}

#pragma mark - private
- (void)playWithImageViewWithURLString:(NSString *)URLString {
    __weak __typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[FFmpegManager sharedManager] openURL:URLString videoSuccess:^(AVFrame *frame) {
            [weakSelf handleVideoFrame:frame];
        } audioSuccess:^(AVFrame *frame) {
            [weakSelf handleAudioFrame:frame];
        } failure:^(NSError *error) {
            NSLog(@"error == %@",error.localizedDescription);
        } decodeEnd:^{
            
        }];
    });
}
NSData * copyFrameData(UInt8 *src, int linesize, int width, int height) {
    width = MIN(linesize, width);
    NSMutableData *md = [[NSMutableData alloc] initWithLength: width * height];
    Byte *dst = md.mutableBytes;
    for (NSUInteger i = 0; i < height; i++) {
        memcpy(dst, src, width);
        dst += width;
        src += linesize;
    }
    return md;
}
- (void)handleVideoFrame:(AVFrame *)videoFrame {
    __weak __typeof(self)weakSelf = self;
    @autoreleasepool {
        UIImage *image = [ECSwsscaleManager getImageFromAVFrame:videoFrame];
        if (self.openGLESView) {
//            AVFrame *rgbFrame = [ECSwsscaleManager getRGBAVFrameFromOtherFormat:videoFrame];
//            [self.openGLESView loadRGBData:rgbFrame->data[0] lenth:rgbFrame->linesize[0] width:rgbFrame->width height:rgbFrame->height];
//            av_free(rgbFrame->data[0]);
//            av_frame_free(&rgbFrame);
            
            NSData *ydata = copyFrameData(videoFrame->data[0], videoFrame->linesize[0], videoFrame->width, videoFrame->height);
            NSData *udata = copyFrameData(videoFrame->data[1], videoFrame->linesize[1], videoFrame->width / 2, videoFrame->height / 2);
            NSData *vdata = copyFrameData(videoFrame->data[2], videoFrame->linesize[2], videoFrame->width / 2, videoFrame->height / 2);
            //            NSLog(@"%d==%d==%d",ydata.length,udata.length,vdata.length);
            [self.openGLESView loadYUV420PDataWithYData:ydata uData:udata vData:vdata width:videoFrame->width height:videoFrame->height];

        }

        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.showImageView.image = image;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                int scale = [UIScreen mainScreen].scale;
                weakSelf.showImageView.W = videoFrame->width / scale;
                weakSelf.showImageView.H = videoFrame->height / scale ;
                weakSelf.showImageView.Y = 40;
                weakSelf.showImageView.X = 0;
                
                ESCOpenGLESView *openglesView = [[ESCOpenGLESView alloc] initWithFrame:CGRectMake(0, 50 + videoFrame->height , videoFrame->width  , videoFrame->height )];
                self.openGLESView = openglesView;
                self.openGLESView.type = ESCVideoDataTypeYUV420;
                [self.view addSubview:openglesView];
                
            });
        });
    }
}


- (void)handleAudioFrame:(AVFrame *)audioFrame {
    AVFrame *pcmFrame = [ESCAACToPCMDecoder getPCMAVFrameFromOtherFormat:audioFrame];
    if (pcmFrame == NULL) {
        NSLog(@"get pcm frame failed!");
    }
    NSData *audioData = [NSData dataWithBytes:pcmFrame->data[0] length:pcmFrame->nb_samples * 2 * 4];
    
    [self.audioPlayer play:audioData];
    
}

@end
