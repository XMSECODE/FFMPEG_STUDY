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
#import "ESCAACToPCMDecoder.h"
#import "ESCAudioStreamPlayer.h"

#import "ECSwsscaleManager.h"
#import "FFmpegManager.h"
#import "FFmpegRemuxer.h"
#import "ESCOpenGLESView.h"
#import "ESCAACToPCMDecoder.h"


@interface ESCRGBVideoPlayViewController ()

@property(nonatomic,strong)ESCAudioStreamPlayer* audioPlayer;

@property(nonatomic,weak)ESCOpenGLESView* openGLESView;

@property(nonatomic,strong)ESCAACToPCMDecoder* aacToPCMDecoder;

@property(nonatomic,strong)ECSwsscaleManager* swsscaleManager;

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
    
    [self playHKTV];
}

- (void)playHKTV {
    NSString *hongkongTVPath = @"rtmp://live.hkstv.hk.lxdns.com/live/hks";
    
    self.audioPlayer = [[ESCAudioStreamPlayer alloc] initWithSampleRate:48000 formatID:kAudioFormatLinearPCM formatFlags:kAudioFormatFlagIsSignedInteger   channelsPerFrame:2 bitsPerChannel:32 framesPerPacket:1];
    
    [self playWithImageViewWithURLString:hongkongTVPath];
}

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
        if (self.swsscaleManager == nil) {
            self.swsscaleManager = [[ECSwsscaleManager alloc] init];
            [self.swsscaleManager initWithAVFrame:videoFrame];
        }
        if (self.openGLESView) {
            AVFrame *rgbFrame = [self.swsscaleManager getRGBAVFrameFromOtherFormat:videoFrame];
            [weakSelf.openGLESView loadRGBData:rgbFrame->data[0] lenth:rgbFrame->linesize[0] width:rgbFrame->width height:rgbFrame->height];
            av_free(rgbFrame->data[0]);
            av_frame_free(&rgbFrame);
            
        }
    }
}

- (void)handleAudioFrame:(AVFrame *)audioFrame {
    if (self.aacToPCMDecoder == nil) {
        self.aacToPCMDecoder = [[ESCAACToPCMDecoder alloc] init];
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
