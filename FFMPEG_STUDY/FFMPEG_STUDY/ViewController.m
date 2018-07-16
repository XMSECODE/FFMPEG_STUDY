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
#import "FFmpegRemuxer.h"


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *showImageView;

@property (nonatomic, strong) NSThread *playThread;

@property (nonatomic, assign) AudioFileStreamID streamID;

@property (nonatomic, assign) BOOL isFailure;

@property (nonatomic, strong) FFmpegRemuxer *remuxer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self playWithImageViewWithURLString:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
    
//    self.remuxer = [[FFmpegRemuxer alloc] init];
//    [self.remuxer moToFlv:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
    
    
    
    //    [self getFirstFrameWithURLString:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
    
//        [self getFirstFrameWithURLString:@"/Users/xiangmingsheng/Music/网易云音乐/Bridge - 雾都历.mp3"];
    
    //    [self getAudioFrameWithURLString:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
    
    
    //    [self getAudioFrameWithURLString:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
    
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
//            printf("%d----%llu----%d---%d---%d    ",frame->sample_rate,frame->channel_layout,frame->nb_samples,frame->format,frame->nb_extended_buf);
            if (self.isFailure == NO) {
                int code = AudioFileStreamParseBytes(self.streamID, frame->linesize[0], frame->data[0], 0);
                AudioFileStreamParseBytes(self.streamID, frame->buf[0]->size, frame->buf[0]->data, 0);
                AudioFileStreamParseBytes(self.streamID, frame->buf[1]->size, frame->buf[1]->data, 0);
                if (code == noErr) {
//                    printf("parseBytes success\n");
                }else {
                    NSLog(@"%d",frame->linesize[0]);
                    printf("parseBytes failure = %d\n",code);
                    self.isFailure = YES;
                    return ;
                }
            }
        } failure:^(NSError *error) {
            NSLog(@"error == %@",error.localizedDescription);
        }];
    });
}

- (void)getAudioFrameWithURLString:(NSString *)URLString {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[FFmpegManager sharedManager] openAudioURL:URLString audioSuccess:^(AVFrame *frame) {
            
        } failure:^(NSError *error) {
            NSLog(@"error == %@",error.localizedDescription);
        }];
    });
    
}

@end
