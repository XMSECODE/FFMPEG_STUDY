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
#import "FFmpegManager.h"
#import "ECOpenGLView.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *showImageView;

@property(nonatomic,weak)ECOpenGLView* openGLView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self playWithImageView];
    
    [self setupView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)setupView {
    ECOpenGLView *openGLView = [[ECOpenGLView alloc] initWithFrame:CGRectMake(0, self.showImageView.H + self.showImageView.Y, self.showImageView.W, self.showImageView.H)];
    self.openGLView = openGLView;
    [self.view addSubview:openGLView];
    self.openGLView.backgroundColor = [UIColor redColor];
}

- (void)playWithImageView {
    __weak __typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[FFmpegManager sharedManager] openURL:@"rtmp://live.hkstv.hk.lxdns.com/live/hks" success:^(AVFrame *frame) {
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
        } failure:^(NSError *error) {
            NSLog(@"error == %@",error.localizedDescription);
        }];
    });
}

@end
