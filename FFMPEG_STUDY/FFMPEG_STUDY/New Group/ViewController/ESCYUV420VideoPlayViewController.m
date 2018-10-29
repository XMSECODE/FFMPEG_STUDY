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
#import "ESCPCMRedecoder.h"
#import "ESCAudioStreamPlayer.h"

#import "ECSwsscaleManager.h"
#import "ESCFFmpegFileTool.h"
#import "FFmpegRemuxer.h"
#import "ESCOpenGLESView.h"
#import "ESCPCMRedecoder.h"
#import "ESCMediaDataModel.h"
#import "x264.h"
#import "ESCYUVToH264Encoder.h"
#import "ESCH264FileToMp4FileTool.h"

#import "ESCffmpegRecorder.h"

@interface ESCYUV420VideoPlayViewController () <ESCYUVToH264EncoderDelegate>

@property(nonatomic,strong)ESCAudioStreamPlayer* audioPlayer;

@property(nonatomic,weak)ESCOpenGLESView* openGLESView;

@property(nonatomic,strong)ESCPCMRedecoder* aacToPCMDecoder;

@property(nonatomic,strong)ECSwsscaleManager* swsscaleManager;

@property(nonatomic,strong)NSMutableArray <ESCMediaDataModel *>* videoFrameArray;

@property(nonatomic,strong)NSMutableArray<ESCMediaDataModel*>* audioFrameArray;

@property(nonatomic,assign)NSInteger width;

@property(nonatomic,assign)NSInteger height;

@property(nonatomic,strong)NSTimer* timer;

@property(nonatomic,strong)dispatch_queue_t queue;

@property(nonatomic,assign)double startTime;

@property(nonatomic,assign)double currentTime;

@property(nonatomic,assign)NSInteger receiveVideoFrameCount;

@property(nonatomic,strong)ESCYUVToH264Encoder* encoder;

@property(nonatomic,strong)ESCH264StreamToMp4FileTool* h264StreamToMp4FileTool;

@property(nonatomic,copy)NSString* saveH264Path;

@property(nonatomic,copy)NSString* saveMp4Path;

@property(nonatomic,assign)BOOL isStartRecord;

@property(nonatomic,strong)ESCMediaInfoModel* mediaInfoModel;

@property(nonatomic,strong)ESCffmpegRecorder* ffmpegRecorder;

@property(nonatomic,strong)ESCFFmpegFileTool* ffmpegManager;

@property(nonatomic,strong)NSMutableArray<ESCFrameDataModel*>* audioPacketModelArray;

@property(nonatomic,strong)NSMutableArray<ESCFrameDataModel*>* videoPacketModelArray;

@end

@implementation ESCYUV420VideoPlayViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    
//    NSString *saveH264Path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
//    NSString *mp4Path = [NSString stringWithFormat:@"%@/tem.mp4",saveH264Path];
//    saveH264Path = [NSString stringWithFormat:@"%@/tem.h264",saveH264Path];
//    
//    if ([[NSFileManager defaultManager] fileExistsAtPath:saveH264Path]) {
//        [[NSFileManager defaultManager] removeItemAtPath:saveH264Path error:nil];
//    }
//    
//    NSString *yuvFilePath = [[NSBundle mainBundle] pathForResource:@"tem1280_720.yuv" ofType:nil];
//    
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//    double startTime = CFAbsoluteTimeGetCurrent();
//    [ESCYUVToH264Encoder yuvToH264EncoderWithVideoWidth:1280 height:720 yuvFilePath:yuvFilePath h264FilePath:saveH264Path frameRate:25];
//    [ESCH264FileToMp4FileTool ESCH264FileToMp4FileToolWithh264FilePath:saveH264Path mp4FilePath:mp4Path videoWidth:1280 videoHeight:720 frameRate:25];
//    double endTime = CFAbsoluteTimeGetCurrent();
//    double time = endTime - startTime;
//    NSLog(@"time===========%f",time);
//    
//    });

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
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"开始录制视频" style:UIBarButtonItemStyleDone target:self action:@selector(startRecorderVideo)];

    
    [self playVideo];
}

- (void)dealloc {
    NSLog(@"dealloc %@",self);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.ffmpegManager stop];
    [self.timer invalidate];
}

- (void)startRecorderVideo {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"停止录制视频" style:UIBarButtonItemStyleDone target:self action:@selector(stopRecorderVideo)];
    dispatch_async(self.queue, ^{
        if (self.encoder == nil) {
            self.encoder = [[ESCYUVToH264Encoder alloc] init];
            NSString *cachesPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"yyyy_MM_dd_HH_mm_ss";
            NSString *datestring = [dateFormatter stringFromDate:[NSDate date]];
            NSString *saveH264Path = [NSString stringWithFormat:@"%@/%@.h264",cachesPath,datestring];
            NSString *mp4Path = [NSString stringWithFormat:@"%@/%@.mp4",cachesPath,datestring];
            self.saveH264Path = saveH264Path;
            self.saveMp4Path = mp4Path;
            self.isStartRecord = YES;
//            [self.encoder setupVideoWidth:self.width height:self.height frameRate:25 h264FilePath:saveH264Path];
            [self.encoder setupVideoWidth:self.width height:self.height frameRate:25 delegate:self];
//            self.h264StreamToMp4FileTool = [[ESCH264StreamToMp4FileTool alloc] initWithVideoSize:CGSizeMake(self.width, self.height) filePath:self.saveMp4Path frameRate:25];

            self.ffmpegRecorder = [ESCffmpegRecorder recordFileWithFilePath:self.saveMp4Path codecType:AV_CODEC_ID_H264 videoWidth:self.width videoHeight:self.height videoFrameRate:25];
        }
        
        
    });
    
}

- (void)stopRecorderVideo {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"开始录制视频" style:UIBarButtonItemStyleDone target:self action:@selector(startRecorderVideo)];
    dispatch_async(self.queue, ^{
        self.isStartRecord = NO;
        
        if(self.encoder){
            [self.encoder endYUVDataStream];
            self.encoder = nil;
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                dispatch_async(dispatch_get_global_queue(0, 0), ^{
//                    [ESCH264FileToMp4FileTool ESCH264FileToMp4FileToolWithh264FilePath:self.saveH264Path mp4FilePath:self.saveMp4Path videoWidth:self.width videoHeight:self.height frameRate:25];
//                });
//            });
        }
    });
}

- (void)playVideo {
    
    self.audioPlayer = [[ESCAudioStreamPlayer alloc] initWithSampleRate:48000 formatID:kAudioFormatLinearPCM formatFlags:kAudioFormatFlagIsSignedInteger channelsPerFrame:2 bitsPerChannel:32 framesPerPacket:1];
    self.audioPacketModelArray = [NSMutableArray array];
    self.videoPacketModelArray = [NSMutableArray array];
    __weak __typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self.ffmpegManager = [[ESCFFmpegFileTool alloc] init];
        [self.ffmpegManager openURL:self.videoPath success:^(ESCMediaInfoModel *infoModel) {
            self.mediaInfoModel = infoModel;
            //开始读取数据
            [self play];
        } failure:^(NSError *error) {
            //提示失败
            NSLog(@"%@",error);
        }];
    });
}

- (void)readData {
    //读取数据
    [self.ffmpegManager readPacketVideoSuccess:^(ESCFrameDataModel *model) {
        [self.videoPacketModelArray addObject:model];
    } audioSuccess:^(ESCFrameDataModel *model) {
        [self.audioPacketModelArray addObject:model];
    } failure:^(NSError *error) {
        
    } decodeEnd:^{
        
    }];
}

- (void)play {

    dispatch_async(self.queue, ^{
        //缓存数据
        while (1) {
            if (self.videoPacketModelArray.count <= 50) {
                [self readData];
            }else {
                //缓存完成
                printf("缓存完成\n");
                break;
            }
        }
        //开始定时解码播放
        
        NSTimer *playTimer = [NSTimer timerWithTimeInterval:1.0 / self.mediaInfoModel.videoFrameRate target:self selector:@selector(decodeAndRender) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:playTimer forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] run];
        self.timer = playTimer;
    });
}

- (void)decodeAndRender {
    double currentTime = CACurrentMediaTime();
    
    printf("开始解码渲染%lf\n",currentTime - self.startTime);
    self.startTime = currentTime;
    [self readData];
    if (self.videoPacketModelArray.count > 0) {
        ESCFrameDataModel *videoModel = self.videoPacketModelArray.firstObject;
        [self.videoPacketModelArray removeObject:videoModel];
        [self.ffmpegManager decodePacket:videoModel videoSuccess:^(ESCFrameDataModel *model) {
//            printf("解码完成\n");
            [self handleVideoFrame:model.frame];
        } audioSuccess:nil failure:^(NSError *error) {
            
        }];
    }
    if (self.audioPacketModelArray.count > 0) {
        ESCFrameDataModel *audioModel = self.audioPacketModelArray.firstObject;
    }
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
    @autoreleasepool {
        if (self.swsscaleManager == nil) {
            self.swsscaleManager = [[ECSwsscaleManager alloc] init];
            [self.swsscaleManager initWithAVFrame:videoFrame];
        }
        
        NSInteger pts = videoFrame->pts;
        self.receiveVideoFrameCount++;
        if (self.openGLESView) {
            NSData *ydata = copyFrameData(videoFrame->data[0], videoFrame->linesize[0], videoFrame->width, videoFrame->height);
            NSData *udata = copyFrameData(videoFrame->data[1], videoFrame->linesize[1], videoFrame->width / 2, videoFrame->height / 2);
            NSData *vdata = copyFrameData(videoFrame->data[2], videoFrame->linesize[2], videoFrame->width / 2, videoFrame->height / 2);
            if (self.width == 0 || self.height == 0) {
                self.width = videoFrame->width;
                self.height = videoFrame->height;
            }
//            printf("渲染数据");
//                if (self.startTime == 0) {
//                    self.startTime = CACurrentMediaTime();
//                }
            //                self.currentTime = (CACurrentMediaTime() - self.startTime) * 1000;
            
                //                    if (videopts - self.currentTime <= 50) {
            [self.openGLESView loadYUV420PDataWithYData:ydata uData:udata vData:vdata width:self.width height:self.height];
            //                    }
            
            //                    ESCMediaDataModel *audioModel = [self.audioFrameArray firstObject];
            //                    if (audioModel) {
            //                        //                printf("audio data==%d==%d==%d\n",self.audioFrameArray.count,videopts,audioModel.pts);
            //                        if (audioModel.pts - self.currentTime < 100) {
            //                            [self.audioFrameArray removeObject:audioModel];
            //                            [self.audioPlayer play:audioModel.audioData];
            //                        }
            //                    }
            if (self.encoder && self.isStartRecord == YES) {
                NSMutableData *yuvData = [NSMutableData data];
                [yuvData appendData:ydata];
                [yuvData appendData:udata];
                [yuvData appendData:vdata];
                
                [self.encoder encoderYUVData:yuvData];
            }
        }
        
    }
}

- (void)handleAudioFrame:(AVFrame *)audioFrame {
    printf("接收到音频数据\n");
    if (self.timer == nil && self.audioFrameArray.count > 100) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(play) userInfo:nil repeats:YES];
            NSLog(@"timer");
        });
    }
    if (self.aacToPCMDecoder == nil) {
        self.aacToPCMDecoder = [[ESCPCMRedecoder alloc] init];
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

#pragma mark - ESCYUVToH264EncoderDelegate
- (void)encoder:(ESCYUVToH264Encoder*)encoder h264Data:(void *)h264Data dataLenth:(NSInteger)lenth {
    NSData *data = [NSData dataWithBytes:h264Data length:lenth];
//    [self.h264StreamToMp4FileTool pushH264DataContentSpsAndPpsData:data];

    if (self.ffmpegRecorder) {
        [self.ffmpegRecorder writeVideoFrame:h264Data length:lenth];
    }
}

- (void)encoderEnd:(ESCYUVToH264Encoder *)encoder {
//    [self.h264StreamToMp4FileTool endWritingCompletionHandler:^{
//
//    }];

    [self.ffmpegRecorder stopRecord];
    self.ffmpegRecorder = nil;
}

@end
