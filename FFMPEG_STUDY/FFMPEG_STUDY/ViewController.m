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
#import "YUVView.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *showImageView;

@property(nonatomic,strong)NSFileHandle* audioFileHandle;

@property(nonatomic,assign)NSInteger writeAudioDataFrameCount;

@property(nonatomic,strong)ESCAudioStreamPlayer* audioPlayer;

@property(nonatomic,weak)ESCOpenGLESView* openGLESView;

@property(nonatomic,weak)YUVView* testView;

@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    
   
    
    [self playHKTV];
}

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

- (void)handleVideoFrame:(AVFrame *)videoFrame {
    __weak __typeof(self)weakSelf = self;
    @autoreleasepool {
        UIImage *image = [ECSwsscaleManager getImageFromAVFrame:videoFrame];
        if (self.openGLESView) {
//            AVFrame *rgbFrame = [ECSwsscaleManager getRGBAVFrameFromOtherFormat:videoFrame];
//            [self.openGLESView loadRGBData:rgbFrame->data[0] lenth:rgbFrame->linesize[0] width:rgbFrame->width height:rgbFrame->height];
//            av_free(rgbFrame->data[0]);
//            av_frame_free(&rgbFrame);
            
            NSData *ydata = [NSData dataWithBytes:videoFrame->data[0] length:videoFrame->width * videoFrame->height];
            NSData *udata = [NSData dataWithBytes:videoFrame->data[1] length:videoFrame->width * videoFrame->height / 4];
            NSData *vdata = [NSData dataWithBytes:videoFrame->data[2] length:videoFrame->width * videoFrame->height / 4];
            //            NSLog(@"%d==%d==%d",ydata.length,udata.length,vdata.length);
            [self.openGLESView loadYUV420PDataWithYData:ydata uData:udata vData:vdata width:videoFrame->width height:videoFrame->height];


//            NSMutableData *data = [ydata mutableCopy];
//            [data appendData:udata];
//            [data appendData:vdata];
//            void* vodata = [data bytes];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.testView displayYUVI420Data:vodata width:480 height:288];
//        });
        
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.showImageView.image = image;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                int scale = [UIScreen mainScreen].scale;
                weakSelf.showImageView.W = image.size.width / scale;
                weakSelf.showImageView.H = image.size.height / scale ;
                weakSelf.showImageView.Y = 40;
                weakSelf.showImageView.X = 0;
                
                ESCOpenGLESView *openglesView = [[ESCOpenGLESView alloc] initWithFrame:CGRectMake(0, 50 + image.size.height , image.size.width / scale , image.size.height / scale)];
                self.openGLESView = openglesView;
                self.openGLESView.type = ESCVideoDataTypeYUV420;
                [self.view addSubview:openglesView];
//                    YUVView *testview = [[YUVView alloc] initWithFrame:CGRectMake(0, 50 + image.size.height , image.size.width , image.size.height)];
//                    [testview setUp];
//                    [self.view addSubview:testview];
//                    self.testView = testview;
                
            });
        });
    }
}

void audioQueueOutputCallback(
                                 void * __nullable       inUserData,
                                 AudioQueueRef           inAQ,
                                 AudioQueueBufferRef     inBuffer) {
    
}

- (void)handleAudioFrame:(AVFrame *)audioFrame {
//    AVFrame *pcmFrame = [ESCAACToPCMDecoder getPCMAVFrameFromOtherFormat:audioFrame];
//    if (pcmFrame == NULL) {
//        NSLog(@"get pcm frame failed!");
//    }
//    NSData *audioData = [NSData dataWithBytes:pcmFrame->data[0] length:pcmFrame->linesize[0]];
    
//    char pcm[10240];
//    int lenth;
//    [self.audioPlayer play:audioData];
    
}

@end
