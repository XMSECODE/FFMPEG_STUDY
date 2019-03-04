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

@property(nonatomic,assign)AVFrame* currentVideoFrame;

@end

@implementation ESCRGBVideoPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"RGB Player";

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

- (void)dealloc {
    NSLog(@"%@====%s",self,__FUNCTION__);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.playQueue cancelAllOperations];
    __weak __typeof(self)weakSelf = self;
    [self.playQueue addOperationWithBlock:^{
        [weakSelf.timer invalidate];
        weakSelf.timer = nil;
        [weakSelf.playrunloop cancelPerformSelectorsWithTarget:weakSelf];
        [weakSelf.ffmpegManager stop];
        weakSelf.ffmpegManager = nil;
        if (weakSelf.currentVideoFrame != nil) {
            av_free(self.currentVideoFrame->data[0]);
            AVFrame *frame = weakSelf.currentVideoFrame;
            av_frame_free(&frame);
        }
    }];
}

- (void)playVideo {
    
    self.audioPlayer = [[ESCAudioStreamPlayer alloc] initWithSampleRate:48000 formatID:kAudioFormatLinearPCM formatFlags:kAudioFormatFlagIsSignedInteger   channelsPerFrame:2 bitsPerChannel:32 framesPerPacket:1];
    
    [self playWithImageViewWithURLString:self.videoPath];
}

- (void)playWithImageViewWithURLString:(NSString *)URLString {
    __weak __typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        weakSelf.ffmpegManager = [[ESCFFmpegFileTool alloc] init];
        [weakSelf.ffmpegManager openURL:URLString success:^(ESCMediaInfoModel *infoModel) {
            weakSelf.mediaInfoModel = infoModel;
            //开始读取数据
            [weakSelf play];
        } failure:^(NSError *error) {
            
        }];
    });
}

- (void)play {
    //开始定时解码播放
    __weak __typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSTimer *playTimer = [NSTimer timerWithTimeInterval:1.0 / weakSelf.mediaInfoModel.videoFrameRate target:weakSelf selector:@selector(decodeAndRender) userInfo:nil repeats:YES];
        weakSelf.timer = playTimer;
        weakSelf.playrunloop = [NSRunLoop currentRunLoop];
        [[NSRunLoop currentRunLoop] addTimer:playTimer forMode:NSRunLoopCommonModes];
        [[NSRunLoop currentRunLoop] run];
    });
}

- (void)decodeAndRender {
    __weak __typeof(self)weakSelf = self;
    [self.playQueue addOperationWithBlock:^{
        //计时
        double currentTime = CACurrentMediaTime();
        printf("开始解码渲染%lf==\n",currentTime - self.startTime);
        
        weakSelf.startTime = currentTime;
        
        //读取数据
        [weakSelf.ffmpegManager readPacketVideoSuccess:^(ESCFrameDataModel *model) {
            [weakSelf.ffmpegManager decodePacket:model
                              outPixelFormat:ESCPixelFormatRGB
                                videoSuccess:^(ESCFrameDataModel *model) {
                                    //            printf("解码完成\n");
                                    self.currentVideoFrame = model.frame;
                                    [weakSelf handleVideoFrame:model.frame];
                                } audioSuccess:nil failure:^(NSError *error) {
                                    
                                }];
        } audioSuccess:^(ESCFrameDataModel *model) {
            [weakSelf decodeAndRender];
        } failure:^(NSError *error) {
            
        } decodeEnd:^{
            
        }];
    }];
}


- (void)handleVideoFrame:(AVFrame *)rgbFrame {
    @autoreleasepool {
        if (self.openGLESView) {
            [self.openGLESView loadRGBData:rgbFrame->data[0] lenth:rgbFrame->linesize[0] width:rgbFrame->width height:rgbFrame->height];
        }
        av_free(rgbFrame->data[0]);
        av_frame_free(&rgbFrame);
        self.currentVideoFrame = nil;
        NSLog(@"%s",__FUNCTION__);
    }
}

@end
