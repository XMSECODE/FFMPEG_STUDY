//
//  ESCYUV420VideoPlayViewController.m
//  FFMPEG_STUDY
//
//  Created by xiangmingsheng on 2018/7/29.
//  Copyright © 2018年 XMSECODE. All rights reserved.
//

#import "ESCYUV420VideoPlayViewController.h"
#import "Header.h"
#import "ESCPCMRedecoder.h"
#import "ESCAudioStreamPlayer.h"
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

@property(nonatomic,assign)NSInteger width;

@property(nonatomic,assign)NSInteger height;

@property(nonatomic,strong)NSTimer* timer;

@property(nonatomic,strong)NSOperationQueue* playQueue;

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

@property(nonatomic,strong)NSRunLoop* playrunloop;

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
    
    self.playQueue = [[NSOperationQueue alloc] init];
    self.playQueue.maxConcurrentOperationCount = 1;
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
    [self stopPlay];
}

- (void)stopPlay {
    [self.playQueue cancelAllOperations];
    __weak __typeof(self)weakSelf = self;
    [self.playQueue addOperationWithBlock:^{
        [weakSelf.timer invalidate];
        weakSelf.timer = nil;
        [weakSelf.playrunloop cancelPerformSelectorsWithTarget:weakSelf];
        [weakSelf.ffmpegManager stop];
        [weakSelf.ffmpegManager freeModelArray:weakSelf.audioPacketModelArray];
        [weakSelf.ffmpegManager freeModelArray:weakSelf.videoPacketModelArray];
        weakSelf.ffmpegManager = nil;
        [weakSelf.audioPlayer stop];
        [weakSelf.aacToPCMDecoder destroy];
    }];
}

- (void)startRecorderVideo {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"停止录制视频" style:UIBarButtonItemStyleDone target:self action:@selector(stopRecorderVideo)];
    __weak __typeof(self)weakSelf = self;
    [self.playQueue addOperationWithBlock:^{
        if (weakSelf.encoder == nil) {
            weakSelf.encoder = [[ESCYUVToH264Encoder alloc] init];
            NSString *cachesPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"yyyy_MM_dd_HH_mm_ss";
            NSString *datestring = [dateFormatter stringFromDate:[NSDate date]];
            NSString *saveH264Path = [NSString stringWithFormat:@"%@/%@.h264",cachesPath,datestring];
            NSString *mp4Path = [NSString stringWithFormat:@"%@/%@.mp4",cachesPath,datestring];
            weakSelf.saveH264Path = saveH264Path;
            weakSelf.saveMp4Path = mp4Path;
            weakSelf.isStartRecord = YES;
            //            [self.encoder setupVideoWidth:self.width height:self.height frameRate:25 h264FilePath:saveH264Path];
            [weakSelf.encoder setupVideoWidth:weakSelf.width height:weakSelf.height frameRate:25 delegate:weakSelf];
            //            self.h264StreamToMp4FileTool = [[ESCH264StreamToMp4FileTool alloc] initWithVideoSize:CGSizeMake(self.width, self.height) filePath:self.saveMp4Path frameRate:25];
            
            weakSelf.ffmpegRecorder = [ESCffmpegRecorder recordFileWithFilePath:weakSelf.saveMp4Path codecType:AV_CODEC_ID_H264 videoWidth:weakSelf.width videoHeight:weakSelf.height videoFrameRate:25];
        }
    }];
}

- (void)stopRecorderVideo {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"开始录制视频" style:UIBarButtonItemStyleDone target:self action:@selector(startRecorderVideo)];
    __weak __typeof(self)weakSelf = self;
    [self.playQueue addOperationWithBlock:^{
        weakSelf.isStartRecord = NO;
        
        if(weakSelf.encoder){
            [weakSelf.encoder endYUVDataStream];
            weakSelf.encoder = nil;
            //            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //                dispatch_async(dispatch_get_global_queue(0, 0), ^{
            //                    [ESCH264FileToMp4FileTool ESCH264FileToMp4FileToolWithh264FilePath:self.saveH264Path mp4FilePath:self.saveMp4Path videoWidth:self.width videoHeight:self.height frameRate:25];
            //                });
            //            });
        }
    }];
}

- (void)playVideo {
    
    self.audioPlayer = [[ESCAudioStreamPlayer alloc] initWithSampleRate:48000 formatID:kAudioFormatLinearPCM formatFlags:kAudioFormatFlagIsSignedInteger channelsPerFrame:2 bitsPerChannel:32 framesPerPacket:1];
    self.audioPacketModelArray = [NSMutableArray array];
    self.videoPacketModelArray = [NSMutableArray array];
    __weak __typeof(self)weakSelf = self;
    [self.playQueue addOperationWithBlock:^{
        weakSelf.ffmpegManager = [[ESCFFmpegFileTool alloc] init];
        [weakSelf.ffmpegManager openURL:weakSelf.videoPath success:^(ESCMediaInfoModel *infoModel) {
            weakSelf.mediaInfoModel = infoModel;
            //开始读取数据
            [weakSelf play];
        } failure:^(NSError *error) {
            //提示失败
            NSLog(@"%@",error);
        }];
    }];
}

- (void)play {
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
    __weak __typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSTimer *playTimer = [NSTimer timerWithTimeInterval:1.0 / weakSelf.mediaInfoModel.videoFrameRate target:weakSelf selector:@selector(decodeAndRender) userInfo:nil repeats:YES];
        weakSelf.timer = playTimer;
        weakSelf.playrunloop = [NSRunLoop currentRunLoop];
        [[NSRunLoop currentRunLoop] addTimer:playTimer forMode:NSRunLoopCommonModes];
        [[NSRunLoop currentRunLoop] run];
    });
}

- (void)readData {
    //读取数据
    __weak __typeof(self)weakSelf = self;
    [self.ffmpegManager readPacketVideoSuccess:^(ESCFrameDataModel *model) {
        [weakSelf.videoPacketModelArray addObject:model];
    } audioSuccess:^(ESCFrameDataModel *model) {
        [weakSelf.audioPacketModelArray addObject:model];
        [weakSelf decodeAndRender];
    } failure:^(NSError *error) {
        [self stopPlay];
    }];
}

- (void)decodeAndRender {
    __weak __typeof(self)weakSelf = self;
    [self.playQueue addOperationWithBlock:^{
        [weakSelf readData];
        if (weakSelf.videoPacketModelArray.count > 0) {
            ESCFrameDataModel *videoModel = weakSelf.videoPacketModelArray.firstObject;
            [weakSelf.videoPacketModelArray removeObject:videoModel];
            [weakSelf.ffmpegManager decodePacket:videoModel
                              outPixelFormat:ESCPixelFormatYUV420
                                videoSuccess:^(ESCFrameDataModel *model) {
                //            printf("解码完成\n");
                                    
                                    //计时
                                    double currentTime = CACurrentMediaTime();
                                    printf("开始解码渲染%lf==\n",currentTime - weakSelf.startTime);
                                    weakSelf.startTime = currentTime;
                                    [weakSelf handleVideoFrame:model.frame];
            } audioSuccess:nil failure:^(NSError *error) {
                
            }];
        }
        while (weakSelf.audioPacketModelArray.count > 0) {
            ESCFrameDataModel *audioModel = weakSelf.audioPacketModelArray.firstObject;
            [weakSelf.audioPacketModelArray removeObject:audioModel];
            [weakSelf.ffmpegManager decodePacket:audioModel outPixelFormat:0 videoSuccess:nil audioSuccess:^(ESCFrameDataModel *model) {
                [weakSelf handleAudioFrame:model.frame];
            } failure:^(NSError *error) {
                
            }];
        }
    }];
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
            //                printf("audio data==%d==%d==%d\n",self.audioFrameArray.count,videopts,audioModel.pts);
//        if (audioModel.pts - self.currentTime < 100) {
        [self.audioPlayer play:audioData];
//        }
        
        

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
