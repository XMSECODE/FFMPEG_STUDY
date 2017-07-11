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
#import "OpenGLView20.h"
#import "imgutils.h"
#import "opt.h"
#import "Header.h"

#import "ECSwsscaleManager.h"
#import "FFmpegManager.h"
#import "ECOpenGLView.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *showImageView;

@property(nonatomic,weak)ECOpenGLView* openGLView;

@property(nonatomic,assign)NSInteger i;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.i = 0;
    
//    [self playWithImageViewWithURLString:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
    [self playWithImageViewWithURLString:@"/Users/xiangmingsheng/Music/网易云音乐/Bridge - 雾都历.mp3"];
    
    [self setupView];
    
//    [self getFirstFrameWithURLString:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
    
//    [self getFirstFrameWithURLString:@"/Users/xiangmingsheng/Music/网易云音乐/Bridge - 雾都历.mp3"];
    
//    [self getAudioFrameWithURLString:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
    
//    [self playAudioWithURLString:@"/Users/xiangmingsheng/Music/网易云音乐/Bridge - 雾都历.mp3"];
    
    
}

- (void)setupView {
    ECOpenGLView *openGLView = [[ECOpenGLView alloc] initWithFrame:CGRectMake(0, self.showImageView.H + self.showImageView.Y, self.showImageView.W, self.showImageView.H)];
    self.openGLView = openGLView;
    [self.view addSubview:openGLView];
}

#pragma mark - private
- (void)playWithImageViewWithURLString:(NSString *)URLString {
    __weak __typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[FFmpegManager sharedManager] openURL:URLString videoSuccess:^(AVFrame *frame) {
            @autoreleasepool {
                UIImage *image = [ECSwsscaleManager getImageFromAVFrame:frame];
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.showImageView.image = image;
                    static dispatch_once_t onceToken;
                    dispatch_once(&onceToken, ^{
                        int scale = [UIScreen mainScreen].scale;
                        weakSelf.showImageView.W = image.size.width / scale;
                        weakSelf.showImageView.H = image.size.height / scale;
                    });
                });
            }
        } audioSuccess:^(AVFrame *frame) {
            
        } failure:^(NSError *error) {
            NSLog(@"error == %@",error.localizedDescription);
        }];
    });
}

- (void)getFirstFrameWithURLString:(NSString *)URLString {
    __weak __typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[FFmpegManager sharedManager] getFirstVideoFrameWithURL:URLString success:^(AVFrame *firstFrame) {
            NSLog(@"get first frame success");
            weakSelf.openGLView.avFrame = firstFrame;
        } failure:^(NSError *error) {
            NSLog(@"error == %@",error.localizedDescription);
        }];
    });
}

- (void)playAudioWithImageViewWithURLString:(NSString *)URLString {
    [[FFmpegManager sharedManager] getPCMDataAudioURL:URLString audioSuccess:^(NSData *PCMData) {
        
    } failure:^(NSError *error) {
        NSLog(@"error == %@",error.localizedDescription);
    }];
}

- (void)getAudioFrameWithURLString:(NSString *)URLString {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[FFmpegManager sharedManager] openAudioURL:URLString audioSuccess:^(AVFrame *frame) {
            
        } failure:^(NSError *error) {
            NSLog(@"error == %@",error.localizedDescription);
        }];
    });
    
}

- (void)playAudioWithURLString:(NSString *)URLString {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[FFmpegManager sharedManager] getPCMDataAudioURL:URLString audioSuccess:^(NSData *PCMData) {
            NSError *error;
//            int ii = [PCMData writeToFile:@"/Users/xiangmingsheng/Music/网易云音乐/Bs.mp3" atomically:YES];
            AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithData:PCMData error:&error];
            if (error == nil) {
                [player prepareToPlay];
            }
        } failure:^(NSError *error) {
            
        }];
    });
}

@end
