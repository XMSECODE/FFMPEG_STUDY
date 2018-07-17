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

@property(nonatomic,strong)NSFileHandle* audioFileHandle;

@property(nonatomic,assign)NSInteger writeAudioDataFrameCount;

@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *mp4DemoPath = [[NSBundle mainBundle] pathForResource:@"demo.mp4" ofType:nil];
    NSString *hongkongTVPath = @"rtmp://live.hkstv.hk.lxdns.com/live/hks";
    
    [self setupAudioQueue];
    
    [self playWithImageViewWithURLString:hongkongTVPath];
    
}
- (void)setupAudioQueue {
    AudioStreamBasicDescription inFormat;
    inFormat.mSampleRate = 48000;
    inFormat.mFormatID = kAudioFormatMPEG4AAC;
    inFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    
    inFormat.mBitsPerChannel = 16;
    inFormat.mChannelsPerFrame = 2;
    inFormat.mFramesPerPacket = 1;
    inFormat.mBytesPerFrame = inFormat.mBitsPerChannel * inFormat.mChannelsPerFrame / 8;    //4
    inFormat.mBytesPerPacket = inFormat.mFramesPerPacket * inFormat.mBytesPerFrame;         //
    inFormat.mReserved = 0;
    
    AudioStreamBasicDescription audioFormate;
    audioFormate.mSampleRate = 48000;
    audioFormate.mFormatID = kAudioFormatLinearPCM;
    audioFormate.mFormatFlags        = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioFormate.mFramesPerPacket    = 1;//每个数据包多少帧
    audioFormate.mChannelsPerFrame   = 2;//1单声道，2立体声
    audioFormate.mBitsPerChannel     = 16;//语音每采样点占用位数
    audioFormate.mBytesPerFrame      = audioFormate.mBitsPerChannel * audioFormate.mChannelsPerFrame/8;//每帧的bytes数
    audioFormate.mBytesPerPacket     = audioFormate.mBytesPerFrame * audioFormate.mFramesPerPacket;//每个数据包的bytes总数，每帧的bytes数＊每个数据包的帧数
    audioFormate.mReserved           = 0;
    
    AudioQueueRef audioQueueRef;
    
    
    OSStatus status = AudioQueueNewOutput(&inFormat, audioQueueOutputCallback, (__bridge void * _Nullable)(self), NULL, NULL, 0, &audioQueueRef);
    if (status != noErr) {
        NSLog(@"create audio queue f%dle(int)d!%d",status);
        return;
    }
}

#pragma mark - private
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
        UIImage *image = [ECSwsscaleManager getImageFromAVFrame:videoFrame];
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
}

void audioQueueOutputCallback(
                                 void * __nullable       inUserData,
                                 AudioQueueRef           inAQ,
                                 AudioQueueBufferRef     inBuffer) {
    
}

- (void)handleAudioFrame:(AVFrame *)audioFrame {
    NSData *audioData = [NSData dataWithBytes:audioFrame->data[0] length:audioFrame->linesize[0]];

   
    
    
    
    
    return;
    
//    NSLog(@"%d",audioFrame->linesize[0]);
//    //先加7位头
//    //aac header 8192
//    unsigned char adtsHeader[7] = {0};
//    adtsHeader[0] = 0xFF;
//    adtsHeader[1] = 0xF1; //有的网站给的是F8，这里需要甄别
//    int profile = 2;
//    int freqIdx = 11;///8000   44100对应的值是4
//    int chanCfg = 1; //mono channel
//    int packetLen = audioData.length + 7 ;//inPacket为rtp的payload数据
//    adtsHeader[2] = ((profile -1 )<<6) + (freqIdx << 2) + (chanCfg >> 2);
//    adtsHeader[3] = ((chanCfg & 3) << 6) + (packetLen >> 11);
//    adtsHeader[4] = (packetLen & 0x7ff) >> 3;//(packetLen >> 3) & 0xff;
//    adtsHeader[5] = ((packetLen & 0x7) << 5)|0x1f;
//    adtsHeader[6] = 0xFC;
//
//    char chBuf[25600]={0};
//    memcpy(chBuf, adtsHeader, 7);
//    memcpy(chBuf+7, audioData.bytes, audioData.length);
//    audioData = [NSData dataWithBytes:chBuf length:7 + audioData.length];
    
    
    
   
    
    
    
    
    if (self.audioFileHandle == nil) {
        NSString *audioFilePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
        audioFilePath = [NSString stringWithFormat:@"%@/demo.pcm",audioFilePath];
        if ([[NSFileManager defaultManager] fileExistsAtPath:audioFilePath] == NO) {
            [[NSFileManager defaultManager] createFileAtPath:audioFilePath contents:nil attributes:nil];
        }
        self.audioFileHandle = [NSFileHandle fileHandleForWritingAtPath:audioFilePath];
    }
    if (self.writeAudioDataFrameCount >= 30) {
        [self.audioFileHandle closeFile];
    }else {
        
        
        
        
        //                err = AudioFileStreamParseBytes(myData->audioFileStream, (UInt32)tData.length+7, chBuf, 0);
        
        
        self.writeAudioDataFrameCount++;
        NSLog(@"self.writeAudioDataFrameCount == %d",self.writeAudioDataFrameCount);
        [self.audioFileHandle writeData:audioData];
    }
}

@end
