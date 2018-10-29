//
//  ESCImageVideoPlayViewController.m
//  FFMPEG_STUDY
//
//  Created by xiangmingsheng on 2018/7/29.
//  Copyright © 2018年 XMSECODE. All rights reserved.
//

#import "ESCImageVideoPlayViewController.h"

#import "Header.h"
#import "ESCPCMRedecoder.h"
#import "ESCAudioStreamPlayer.h"

#import "ESCSwsscaleTool.h"
#import "ESCFFmpegFileTool.h"
#import "ESCPCMRedecoder.h"
#import "ESCAudioUnitStreamPlayer.h"

@interface ESCImageVideoPlayViewController ()

@property (weak, nonatomic)UIImageView *showImageView;

@property(nonatomic,strong)ESCAudioStreamPlayer* audioPlayer;

@property(nonatomic,strong)ESCAudioUnitStreamPlayer* unitAudioPlayer;

@property(nonatomic,strong)ESCPCMRedecoder* aacToPCMDecoder;

@property(nonatomic,strong)ESCSwsscaleTool* swsscaleManager;

@property(nonatomic,strong)ESCFFmpegFileTool* ffmpegManager;

@property(nonatomic,strong)ESCMediaInfoModel* mediaInfoModel;

@property(nonatomic,strong)NSTimer* timer;

@property(nonatomic,strong)NSRunLoop* playrunloop;

@property(nonatomic,strong)NSOperationQueue* playQueue;

@property(nonatomic,assign)double startTime;

@end

@implementation ESCImageVideoPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"UIImage Player";
    self.navigationController.navigationBar.barTintColor = [UIColor clearColor];

    self.view.backgroundColor = [UIColor whiteColor];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    self.showImageView = imageView;
    [self.view addSubview:self.showImageView];
    self.showImageView.backgroundColor = [UIColor blackColor];
    self.showImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    [self.showImageView mas_makeConstraints:^(MASConstraintMaker *make) {
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
//    self.unitAudioPlayer = [[ESCAudioUnitStreamPlayer alloc] initWithSampleRate:48000 formatID:kAudioFormatLinearPCM formatFlags:kAudioFormatFlagIsSignedInteger   channelsPerFrame:2 bitsPerChannel:32 framesPerPacket:1];

    
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

- (void)handleVideoFrame:(AVFrame *)videoFrame {
    __weak __typeof(self)weakSelf = self;
    @autoreleasepool {
        if (self.swsscaleManager == nil) {
            self.swsscaleManager = [[ESCSwsscaleTool alloc] init];
            [self.swsscaleManager setupWithAVFrame:videoFrame outFormat:ESCPixelFormatRGB];
        }
        UIImage *image = [self.swsscaleManager getImageFromAVFrame:videoFrame];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.showImageView.image = image;
        });
    }
}

- (void)handleAudioFrame:(AVFrame *)audioFrame {
    if (self.aacToPCMDecoder == nil) {
        self.aacToPCMDecoder = [[ESCPCMRedecoder alloc] init];
        [self.aacToPCMDecoder initConvertWithFrame:audioFrame];
    }
    @autoreleasepool {
        if (self.aacToPCMDecoder) {
            AVFrame *pcmFrame = [self.aacToPCMDecoder getPCMAVFrameFromOtherFormat:audioFrame];
            if (pcmFrame == NULL) {
                NSLog(@"get pcm frame failed!");
            }
            NSData *audioData = [NSData dataWithBytes:pcmFrame->data[0] length:pcmFrame->nb_samples * 2 * 4];
            [self.audioPlayer play:audioData];
//            [self.unitAudioPlayer play:audioData];
        }
    }
    
}
@end
