//
//  ESCYUV420VideoPlayViewController.m
//  FFMPEG_STUDY
//
//  Created by xiangmingsheng on 2018/7/29.
//  Copyright © 2018年 XMSECODE. All rights reserved.
//

#import "ESCYUV420VideoPlayViewController.h"
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
#import "ESCMediaDataModel.h"
#import "x264.h"
#import "ESCYUVToH264Encoder.h"
#import "ESCH264FileToMp4FileTool.h"

@interface ESCYUV420VideoPlayViewController ()

@property(nonatomic,strong)ESCAudioStreamPlayer* audioPlayer;

@property(nonatomic,weak)ESCOpenGLESView* openGLESView;

@property(nonatomic,strong)ESCAACToPCMDecoder* aacToPCMDecoder;

@property(nonatomic,strong)ECSwsscaleManager* swsscaleManager;

@property(nonatomic,strong)NSMutableArray <ESCMediaDataModel *>* videoFrameArray;

@property(nonatomic,strong)NSMutableArray<ESCMediaDataModel*>* audioFrameArray;

@property(nonatomic,assign)NSInteger width;

@property(nonatomic,assign)NSInteger height;

@property(nonatomic,strong)NSTimer* timer;

@property(nonatomic,strong)dispatch_queue_t queue;

@property(nonatomic,assign)double startTime;

@property(nonatomic,assign)double currentTime;

@property(nonatomic,strong)NSFileHandle* temhandle;

@property(nonatomic,strong)ESCYUVToH264Encoder* encoder;

@end

@implementation ESCYUV420VideoPlayViewController




- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *saveH264Path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
    NSString *mp4Path = [NSString stringWithFormat:@"%@/tem.mp4",saveH264Path];
    saveH264Path = [NSString stringWithFormat:@"%@/tem.h264",saveH264Path];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:saveH264Path]) {
        [[NSFileManager defaultManager] removeItemAtPath:saveH264Path error:nil];
    }
    
    NSString *yuvFilePath = [[NSBundle mainBundle] pathForResource:@"tem1280_720.yuv" ofType:nil];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
    double startTime = CFAbsoluteTimeGetCurrent();
    [ESCYUVToH264Encoder yuvToH264EncoderWithVideoWidth:1280 height:720 yuvFilePath:yuvFilePath h264FilePath:saveH264Path frameRate:25];
    [ESCH264FileToMp4FileTool ESCH264FileToMp4FileToolWithh264FilePath:saveH264Path mp4FilePath:mp4Path videoWidth:1280 videoHeight:720 frameRate:25];
    double endTime = CFAbsoluteTimeGetCurrent();
    double time = endTime - startTime;
    NSLog(@"time===========%f",time);
    
    });

    self.videoFrameArray = [NSMutableArray array];
    self.audioFrameArray = [NSMutableArray array];
    
    self.queue = dispatch_queue_create("ff", DISPATCH_QUEUE_SERIAL);
    self.title = @"YUV420 Player";
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    ESCOpenGLESView *openglesView = [[ESCOpenGLESView alloc] init];
    self.openGLESView = openglesView;
    self.openGLESView.type = ESCVideoDataTypeYUV420;
    [self.view addSubview:openglesView];
    
    [self.openGLESView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.left.equalTo(self.view);
        make.width.equalTo(self.view).multipliedBy(2);
        make.height.equalTo(self.view).multipliedBy(2);
    }];
    self.openGLESView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
    self.openGLESView.transform = CGAffineTransformTranslate(self.openGLESView.transform, - self.view.frame.size.width * 1, - self.view.frame.size.height);
    
    self.navigationController.navigationBar.barTintColor = [UIColor clearColor];
    

    
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
            if (self.timer == nil && self.audioFrameArray.count > 100) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(play) userInfo:nil repeats:YES];
                    NSLog(@"timer");
                });
                
            }
            [weakSelf handleAudioFrame:frame];
        } failure:^(NSError *error) {
            NSLog(@"error == %@",error.localizedDescription);
        } decodeEnd:^{
            
        }];
    });
}

- (void)play {
    dispatch_async(self.queue, ^{
        if (self.startTime == 0) {
            self.startTime = CACurrentMediaTime();
        }
        self.currentTime = (CACurrentMediaTime() - self.startTime) * 1000;

        if (self.videoFrameArray.count > 0) {
            ESCMediaDataModel *videoModel = [self.videoFrameArray firstObject];
            NSInteger videopts = videoModel.pts;

            if (videopts - self.currentTime <= 50) {
                [self.videoFrameArray removeObject:videoModel];
                [self.openGLESView loadYUV420PDataWithYData:videoModel.yData uData:videoModel.uData vData:videoModel.vData width:self.width height:self.height];
            }
            
            ESCMediaDataModel *audioModel = [self.audioFrameArray firstObject];
            if (audioModel) {
//                printf("audio data==%d==%d==%d\n",self.audioFrameArray.count,videopts,audioModel.pts);
                if (audioModel.pts - self.currentTime < 100) {
                    [self.audioFrameArray removeObject:audioModel];
                    [self.audioPlayer play:audioModel.audioData];
                }
            }
        }

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
        if (self.swsscaleManager == nil) {
            self.swsscaleManager = [[ECSwsscaleManager alloc] init];
            [self.swsscaleManager initWithAVFrame:videoFrame];
        }
        NSInteger pts = videoFrame->pts;

        if (self.openGLESView) {
            NSData *ydata = copyFrameData(videoFrame->data[0], videoFrame->linesize[0], videoFrame->width, videoFrame->height);
            NSData *udata = copyFrameData(videoFrame->data[1], videoFrame->linesize[1], videoFrame->width / 2, videoFrame->height / 2);
            NSData *vdata = copyFrameData(videoFrame->data[2], videoFrame->linesize[2], videoFrame->width / 2, videoFrame->height / 2);
            if (self.width == 0 || self.height == 0) {
                self.width = videoFrame->width;
                self.height = videoFrame->height;
            }
            dispatch_async(self.queue, ^{
                ESCMediaDataModel *model = [[ESCMediaDataModel alloc] init];
                model.type = 0;
                model.yData = ydata;
                model.uData =udata;
                model.vData = vdata;

                model.pts = pts;
                [self.videoFrameArray addObject:model];
            });
            
        }
    }
}

- (void)handleAudioFrame:(AVFrame *)audioFrame {
    if (self.aacToPCMDecoder == nil) {
        self.aacToPCMDecoder = [[ESCAACToPCMDecoder alloc] init];
        [self.aacToPCMDecoder initConvertWithFrame:audioFrame];
    }
    if (self.aacToPCMDecoder) {
        NSInteger pts = audioFrame->pts;
        AVFrame *pcmFrame = [self.aacToPCMDecoder getPCMAVFrameFromOtherFormat:audioFrame];
        if (pcmFrame == NULL) {
            NSLog(@"get pcm frame failed!");
        }
        
        NSData *audioData = [NSData dataWithBytes:pcmFrame->data[0] length:pcmFrame->nb_samples * 2 * 4];
        dispatch_async(self.queue, ^{
            ESCMediaDataModel *model = [[ESCMediaDataModel alloc] init];
            model.type = 1;
            model.audioData = audioData;
            model.pts = pts;
            [self.audioFrameArray addObject:model];
        });
    }
}

@end
