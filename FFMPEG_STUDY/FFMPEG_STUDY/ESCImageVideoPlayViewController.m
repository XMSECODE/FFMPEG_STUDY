//
//  ESCImageVideoPlayViewController.m
//  FFMPEG_STUDY
//
//  Created by xiangmingsheng on 2018/7/29.
//  Copyright © 2018年 XMSECODE. All rights reserved.
//

#import "ESCImageVideoPlayViewController.h"

#import "Header.h"
#import "ESCAACToPCMDecoder.h"
#import "ESCAudioStreamPlayer.h"

#import "ECSwsscaleManager.h"
#import "FFmpegManager.h"
#import "ESCAACToPCMDecoder.h"
#import "ESCAudioUnitStreamPlayer.h"

@interface ESCImageVideoPlayViewController ()

@property (weak, nonatomic)UIImageView *showImageView;

@property(nonatomic,strong)ESCAudioStreamPlayer* audioPlayer;

@property(nonatomic,strong)ESCAudioUnitStreamPlayer* unitAudioPlayer;

@property(nonatomic,strong)ESCAACToPCMDecoder* aacToPCMDecoder;

@property(nonatomic,strong)ECSwsscaleManager* swsscaleManager;

@end

@implementation ESCImageVideoPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"UIImage Player";
    
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
    
    [self playHKTV];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
}

- (void)playHKTV {
    NSString *hongkongTVPath = @"rtmp://live.hkstv.hk.lxdns.com/live/hks";
    
    self.audioPlayer = [[ESCAudioStreamPlayer alloc] initWithSampleRate:48000 formatID:kAudioFormatLinearPCM formatFlags:kAudioFormatFlagIsSignedInteger   channelsPerFrame:2 bitsPerChannel:32 framesPerPacket:1];
//    self.unitAudioPlayer = [[ESCAudioUnitStreamPlayer alloc] initWithSampleRate:48000 formatID:kAudioFormatLinearPCM formatFlags:kAudioFormatFlagIsSignedInteger   channelsPerFrame:2 bitsPerChannel:32 framesPerPacket:1];

    
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
        UIImage *image = [self.swsscaleManager getImageFromAVFrame:videoFrame];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.showImageView.image = image;
        });
    }
}

- (void)handleAudioFrame:(AVFrame *)audioFrame {
    if (self.aacToPCMDecoder == nil) {
        self.aacToPCMDecoder = [[ESCAACToPCMDecoder alloc] init];
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
