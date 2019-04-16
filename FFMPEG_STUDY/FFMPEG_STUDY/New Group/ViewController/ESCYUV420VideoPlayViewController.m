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
#import "ESCFFmpegFilterTool.h"

@interface ESCYUV420VideoPlayViewController ()

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

@property(nonatomic,copy)NSString* saveH264Path;

@property(nonatomic,copy)NSString* saveMp4Path;

@property(nonatomic,assign)BOOL isStartRecord;

@property(nonatomic,strong)ESCMediaInfoModel* mediaInfoModel;

@property(nonatomic,strong)ESCFFmpegFileTool* ffmpegManager;

@property(nonatomic,strong)NSMutableArray<ESCFrameDataModel*>* audioPacketModelArray;

@property(nonatomic,strong)NSMutableArray<ESCFrameDataModel*>* videoPacketModelArray;

@property(nonatomic,strong)NSRunLoop* playrunloop;

@property(nonatomic,strong)ESCFFmpegFilterTool* filterTool;

@property(nonatomic,assign)int rotateValue;

@property(nonatomic,assign)int paddingValue;

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
        [weakSelf.filterTool destroy];
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
//                                    printf("开始解码渲染%lf==\n",currentTime - weakSelf.startTime);
                                    weakSelf.startTime = currentTime;
                                    if (weakSelf.filterTool == nil) {
                                        
                                        weakSelf.filterTool = [[ESCFFmpegFilterTool alloc] init];
                                        /*
                                         //const char *filter_descr = "scale=78:24,transpose=cclock";
                                         //const char *filter_descr = "scale=300:100,transpose=cclock";
                                         //const char *filter_descr = "drawbox=x=100:y=200:w=200:h=260:color=red@0.5";
                                         //const char *filter_descr = "drawgrid=w=iw/3:h=ih/3:t=2:c=green@0.5";
                                         //const char *filter_descr = "drawgrid=w=iw/3:h=ih/3:t=2:c=green@0.5,drawbox=x=100:y=200:w=200:h=260:color=red@0.5";
                                         //const char *filter_descr = "edgedetect=low=0.1:high=0.4";
                                         colorlevels=romin=0.5:gomin=0.5:bomin=0.5
                                         colorbalance=rs=.3
                                         //颜色调整
                                         colorchannelmixer=.3:.4:.3:0:.3:.4:.3:0:.3:.4:.3
                                         crop=w=100:h=100:x=300:y=500
                                         pad=width=640:height=480:x=0:y=40:color=red
                                         rotate=45*PI/180
                                         scale=700:400:force_original_aspect_ratio=decrease, pad=1280:720:(1280-in_w)/2:(720-in_h)/2,rotate=PI*11/180
                                         */
                                        int owidth = model.frame->width;
                                        int oheight = model.frame->height;
                                        int nwidth = owidth - self.paddingValue++;
                                        int nheight = oheight - self.paddingValue++;
                                        if (nwidth < 0) {
                                            nwidth = 0;
                                        }
                                        if (nheight < 0) {
                                            nheight = 0;
                                        }
                                        //缩小
                                        NSString *filter = [NSString stringWithFormat:@"scale=%d:%d:force_original_aspect_ratio=decrease, pad=%d:%d:(%d-in_w)/2:(%d-in_h)/2,rotate=PI*%d/180",nwidth,nheight,owidth,oheight,owidth,oheight,self.rotateValue++];
                                        //放大
                                        //crop=out_w=2/4*in_w:out_h=2/4*in_h,scale=1920:1080,rotate=PI*90/180
                                        filter = @"crop=out_w=2/4*in_w:out_h=2/4*in_h,scale=1920:1080,rotate=PI*90/180";
                                        NSLog(@"%@",filter);
                                        [weakSelf.filterTool setupWithWidth:model.frame->width
                                                                     height:model.frame->height
                                                                pixelFormat:model.frame->format
                                                                  time_base:model.frame->sample_aspect_ratio
                                                        sample_aspect_ratio:model.frame->sample_aspect_ratio
                                                               filter_descr:filter];
                                        
                                        
                                    }
                                    AVFrame *resultFrame = [self.filterTool filterFrame:model.frame];
                                    if (resultFrame != NULL) {
                                        NSLog(@"%d=====%d",resultFrame->width,resultFrame->height);
                                        model.frame = resultFrame;
                                        [weakSelf handleVideoFrame:model.frame needFree:YES];
                                    }else{
                                        [weakSelf handleVideoFrame:model.frame needFree:NO];
                                    }
                                    [self.filterTool destroy];
                                    self.filterTool = nil;
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

- (void)handleVideoFrame:(AVFrame *)videoFrame needFree:(BOOL)needFree{
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
            if (needFree) {
                av_frame_free(&videoFrame);
            }
//            printf("渲染数据");
//                if (self.startTime == 0) {
//                    self.startTime = CACurrentMediaTime();
//                }
            //                self.currentTime = (CACurrentMediaTime() - self.startTime) * 1000;
            
                //                    if (videopts - self.currentTime <= 50) {
            [self.openGLESView loadYUV420PDataWithYData:ydata uData:udata vData:vdata width:self.width height:self.height];
            //                    }

        }
        
    }
}

- (void)handleAudioFrame:(AVFrame *)audioFrame {
//    printf("接收到音频数据\n");
    
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

@end
