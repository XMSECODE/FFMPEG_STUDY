//
//  ESCRGBVideoPlayViewController.m
//  FFMPEG_STUDY
//
//  Created by xiangmingsheng on 2018/7/29.
//  Copyright © 2018年 XMSECODE. All rights reserved.
//

#import "ESCRGBVideoPlayViewController.h"

#import <AVFoundation/AVFoundation.h>
#import "avformat.h"
#import "avcodec.h"
#import "swscale.h"
#import "imgutils.h"
#import "opt.h"
#import "Header.h"
#import "ESCPCMRedecoder.h"
#import "ESCAudioStreamPlayer.h"

#import "ESCSwsscaleTool.h"
#import "ESCFFmpegFileTool.h"
#import "FFmpegRemuxer.h"
#import "ESCOpenGLESView.h"
#import "ESCPCMRedecoder.h"


@interface ESCRGBVideoPlayViewController ()

@property(nonatomic,strong)ESCAudioStreamPlayer* audioPlayer;

@property(nonatomic,weak)ESCOpenGLESView* openGLESView;

@property(nonatomic,strong)ESCPCMRedecoder* aacToPCMDecoder;

@property(nonatomic,strong)ESCFFmpegFileTool* ffmpegManager;
@property(nonatomic,strong)ESCMediaInfoModel* mediaInfoModel;
@property(nonatomic,strong)NSTimer* timer;
@property(nonatomic,strong)NSRunLoop* playrunloop;

@property(nonatomic,strong)NSOperationQueue* playQueue;

@property(nonatomic,assign)double startTime;
@end

@implementation ESCRGBVideoPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"RGB Player";
    self.navigationController.navigationBar.barTintColor = [UIColor clearColor];

    self.view.backgroundColor = [UIColor whiteColor];
    
    ESCOpenGLESView *openglesView = [[ESCOpenGLESView alloc] init];
    self.openGLESView = openglesView;
    self.openGLESView.type = ESCVideoDataTypeRGB;
    [self.view addSubview:openglesView];
    
    [self.openGLESView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.right.left.equalTo(self.view);
        make.height.equalTo(self.view).multipliedBy(0.6);
    }];
    self.playQueue = [[NSOperationQueue alloc] init];
    self.playQueue.maxConcurrentOperationCount = 1;
    [self playVideo];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.playQueue cancelAllOperations];
    [self.playQueue addOperationWithBlock:^{
        [self.timer invalidate];
        self.timer = nil;
        [self.playrunloop cancelPerformSelectorsWithTarget:self];
        [self.ffmpegManager stop];
        self.ffmpegManager = nil;
    }];
}

- (void)playVideo {
    
    self.audioPlayer = [[ESCAudioStreamPlayer alloc] initWithSampleRate:48000 formatID:kAudioFormatLinearPCM formatFlags:kAudioFormatFlagIsSignedInteger   channelsPerFrame:2 bitsPerChannel:32 framesPerPacket:1];
    
    [self playWithImageViewWithURLString:self.videoPath];
}

- (void)playWithImageViewWithURLString:(NSString *)URLString {
    __weak __typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self.ffmpegManager = [[ESCFFmpegFileTool alloc] init];
        [self.ffmpegManager openURL:URLString success:^(ESCMediaInfoModel *infoModel) {
            self.mediaInfoModel = infoModel;
            //开始读取数据
            [self play];
        } failure:^(NSError *error) {
            
        }];
    });
}

- (void)play {
    //开始定时解码播放
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSTimer *playTimer = [NSTimer timerWithTimeInterval:1.0 / self.mediaInfoModel.videoFrameRate target:self selector:@selector(decodeAndRender) userInfo:nil repeats:YES];
        self.timer = playTimer;
        self.playrunloop = [NSRunLoop currentRunLoop];
        [[NSRunLoop currentRunLoop] addTimer:playTimer forMode:NSRunLoopCommonModes];
        [[NSRunLoop currentRunLoop] run];
    });
}

- (void)decodeAndRender {
    [self.playQueue addOperationWithBlock:^{
        //计时
        double currentTime = CACurrentMediaTime();
        printf("开始解码渲染%lf==\n",currentTime - self.startTime);
        
        self.startTime = currentTime;
        
        //读取数据
        [self.ffmpegManager readPacketVideoSuccess:^(ESCFrameDataModel *model) {
            [self.ffmpegManager decodePacket:model
                              outPixelFormat:ESCPixelFormatRGB
                                videoSuccess:^(ESCFrameDataModel *model) {
                                    //            printf("解码完成\n");
                                    [self handleVideoFrame:model.frame];
                                } audioSuccess:nil failure:^(NSError *error) {
                                    
                                }];
        } audioSuccess:^(ESCFrameDataModel *model) {
            [self decodeAndRender];
        } failure:^(NSError *error) {
            
        } decodeEnd:^{
            
        }];
    }];
}


- (void)handleVideoFrame:(AVFrame *)rgbFrame {
    __weak __typeof(self)weakSelf = self;
    @autoreleasepool {
        if (self.openGLESView) {
            [weakSelf.openGLESView loadRGBData:rgbFrame->data[0] lenth:rgbFrame->linesize[0] width:rgbFrame->width height:rgbFrame->height];
            av_free(rgbFrame->data[0]);
            av_frame_free(&rgbFrame);
            
        }
    }
}

- (void)handleAudioFrame:(AVFrame *)audioFrame {
    if (self.aacToPCMDecoder == nil) {
        self.aacToPCMDecoder = [[ESCPCMRedecoder alloc] init];
        [self.aacToPCMDecoder initConvertWithFrame:audioFrame];
    }
    if (self.aacToPCMDecoder) {
        AVFrame *pcmFrame = [self.aacToPCMDecoder getPCMAVFrameFromOtherFormat:audioFrame];
        if (pcmFrame == NULL) {
            NSLog(@"get pcm frame failed!");
        }
        NSData *audioData = [NSData dataWithBytes:pcmFrame->data[0] length:pcmFrame->nb_samples * 2 * 4];
        
        [self.audioPlayer play:audioData];
    }
}

@end
