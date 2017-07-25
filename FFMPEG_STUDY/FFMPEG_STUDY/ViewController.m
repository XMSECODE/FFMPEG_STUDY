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



static const int kNumberBuffers = 3;

typedef struct AQPlayerState {
    AudioStreamBasicDescription   mDataFormat;
    AudioQueueRef                 mQueue;
    AudioQueueBufferRef           mBuffers[kNumberBuffers];
    AudioFileID                   mAudioFile;
    UInt32                        bufferByteSize;
    SInt64                        mCurrentPacket;
    UInt32                        mNumPacketsToRead;
    AudioStreamPacketDescription  *mPacketDescs;
    bool                          mIsRunning;
}AQPlayerState;

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *showImageView;

@property(nonatomic,weak)ECOpenGLView* openGLView;

@property(nonatomic,assign)NSInteger i;

@property (nonatomic, strong) NSThread *playThread;

//audiostream
@property (nonatomic, strong) NSOperationQueue *streamQueue;
@property (nonatomic, assign) AudioFileStreamID streamID;

@property (nonatomic, assign) AudioStreamBasicDescription* streamDescription;

@end

@implementation ViewController

void  func1_AudioFileStream_PropertyListenerProc(void *							inClientData,
                                                 AudioFileStreamID				inAudioFileStream,
                                                 AudioFileStreamPropertyID		inPropertyID,
                                                 AudioFileStreamPropertyFlags *	ioFlags);

void func2_AudioFileStream_PacketsProc(void *							inClientData,
                                       UInt32							inNumberBytes,
                                       UInt32							inNumberPackets,
                                       const void *					inInputData,
                                       AudioStreamPacketDescription	*inPacketDescriptions);

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.i = 0;
    
    self.streamQueue = [[NSOperationQueue alloc] init];
    self.streamQueue.maxConcurrentOperationCount = 1;
    
    
    [self initAudioStreamQueue];
    
    [self playWithImageViewWithURLString:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
    
    [self setupView];
    
    [self getFirstFrameWithURLString:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
    
//    [self getAudioFrameWithURLString:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
    
    
//    self.playThread = [[NSThread alloc] initWithTarget:self selector:@selector(playMusic) object:nil];
    
//    [self.playThread start];
    
    
}

- (void)initAudioStreamQueue {
    AudioFileStreamID streamID = NULL;
    int code = AudioFileStreamOpen(NULL, func1_AudioFileStream_PropertyListenerProc, func2_AudioFileStream_PacketsProc, 0, &streamID);
    if (code == 0) {
        self.streamID = streamID;
        printf("init Audio Stream Queue success\n");
    }else {
        printf("init Audio Stream Queue failure\n");
        return ;
    }
}

- (void)playMusic {
    [self initAudioQueue:@"/Users/xiang/Music/网易云音乐/Nickelback - Savin' Me.mp3"];
}

- (void)setupView {
    ECOpenGLView *openGLView = [[ECOpenGLView alloc] initWithFrame:CGRectMake(0, self.showImageView.H + self.showImageView.Y, self.showImageView.W, self.showImageView.H)];
    self.openGLView = openGLView;
    [self.view addSubview:openGLView];
}

void  func1_AudioFileStream_PropertyListenerProc(void *							inClientData,
                                                 AudioFileStreamID				inAudioFileStream,
                                                 AudioFileStreamPropertyID		inPropertyID,
                                                 AudioFileStreamPropertyFlags *	ioFlags) {
    if (inPropertyID ==  kAudioFileStreamProperty_DataFormat) {
        UInt32 outDataSize = sizeof(AudioStreamBasicDescription);
        AudioStreamBasicDescription audiostream;
        int code = AudioFileStreamGetProperty(inAudioFileStream, inPropertyID,  &outDataSize, &audiostream);
        if (code == noErr) {
            printf("read audio stream basic description success\n");
        }else {
            printf("read audio stream basic description failuren\n");
        }
    }
    printf("func1\n");
}

void func2_AudioFileStream_PacketsProc(void *							inClientData,
                                    UInt32							inNumberBytes,
                                    UInt32							inNumberPackets,
                                    const void *					inInputData,
                                        AudioStreamPacketDescription	*inPacketDescriptions) {
    printf("func2");
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
            NSBlockOperation *block = [NSBlockOperation blockOperationWithBlock:^{
                int code = AudioFileStreamParseBytes(self.streamID, frame->linesize[0], frame->data[0], 0);
                if (code == noErr) {
                    printf("parseBytes success\n");
                }else {
                    printf("parseBytes failure\n");
                    return ;
                }
//                NSLog(@"%@",[NSThread currentThread]);

            }];
            [self.streamQueue addOperation:block];
            
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

- (void)playVideoWithImageViewWithURLString:(NSString *)URLString {
    
}

- (void)getAudioFrameWithURLString:(NSString *)URLString {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[FFmpegManager sharedManager] openAudioURL:URLString audioSuccess:^(AVFrame *frame) {
            
        } failure:^(NSError *error) {
            
        }];
    });
    
}

- (void)playAudioWithURLString:(NSString *)URLString {
    
}


//The Playback Audio Queue Callback
static void HandleOutputBuffer(void* aqData,AudioQueueRef inAQ,AudioQueueBufferRef inBuffer){
    AQPlayerState *pAqData = (AQPlayerState *) aqData;
    //    if (pAqData->mIsRunning == 0) return; // 注意苹果官方文档这里有这一句,应该是有问题,这里应该是判断如果pAqData->isDone??
    NSLog(@"回调");
    UInt32 numBytesReadFromFile = 4096;
    UInt32 numPackets = pAqData->mNumPacketsToRead;
    //    AudioFileReadPackets(pAqData->mAudioFile,false,&numBytesReadFromFile,pAqData->mPacketDescs,pAqData->mCurrentPacket,&numPackets,inBuffer->mAudioData);
    AudioFileReadPacketData(pAqData->mAudioFile, false, &numBytesReadFromFile, pAqData->mPacketDescs, pAqData->mCurrentPacket, &numPackets, inBuffer->mAudioData);
    
    if (numPackets > 0) {
        NSLog(@"numPackets > 0");
        NSLog(@"播放==%zd",numBytesReadFromFile);
        inBuffer->mAudioDataByteSize = numBytesReadFromFile;
        AudioQueueEnqueueBuffer(inAQ,inBuffer,(pAqData->mPacketDescs ? numPackets : 0),pAqData->mPacketDescs);
        pAqData->mCurrentPacket += numPackets;
    } else {
        NSLog(@"numPackets <= 0");
        if (pAqData->mIsRunning) {
            
        }
        AudioQueueStop(inAQ,false);
        pAqData->mIsRunning = false;
    }
}

void DeriveBufferSize (AudioStreamBasicDescription inDesc,UInt32 maxPacketSize,Float64 inSeconds,UInt32 *outBufferSize,UInt32 *outNumPacketsToRead) {
    
    static const int maxBufferSize = 0x10000;
    static const int minBufferSize = 0x4000;
    
    if (inDesc.mFramesPerPacket != 0) {
        Float64 numPacketsForTime = inDesc.mSampleRate / inDesc.mFramesPerPacket * inSeconds;
        *outBufferSize = numPacketsForTime * maxPacketSize;
    } else {
        *outBufferSize = maxBufferSize > maxPacketSize ? maxBufferSize : maxPacketSize;
    }
    
    if (*outBufferSize > maxBufferSize && *outBufferSize > maxPacketSize){
        *outBufferSize = maxBufferSize;
    }
    else {
        if (*outBufferSize < minBufferSize){
            *outBufferSize = minBufferSize;
        }
    }
    
    *outNumPacketsToRead = *outBufferSize / maxPacketSize;
}

- (void)initAudioQueue:(NSString *)localFilePath {
    
    AQPlayerState aqData;
    
    CFStringRef cfFilePath = (__bridge CFStringRef)localFilePath;
    //创建url
    CFURLRef cfURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,cfFilePath , kCFURLPOSIXPathStyle, false);
    //打开文件
    int error = AudioFileOpenURL(cfURL, kAudioFileReadPermission, 0, &aqData.mAudioFile);
    if ([self checkError:error] == NO) {
        return;
    }else {
        NSLog(@"打开文件成功");
    }
    //释放url
    CFRelease(cfURL);
    //计算结构体数据大小
    UInt32 dateFormatSize = sizeof(aqData.mDataFormat);
    NSLog(@"dateFormatSize == %zd",dateFormatSize);
    //获取格式
    error = AudioFileGetProperty(aqData.mAudioFile, kAudioFilePropertyDataFormat, &dateFormatSize, &aqData.mDataFormat);
    if ([self checkError:error] == NO) {
        NSLog(@"格式获取失败");
        return;
    }else {
        NSLog(@"格式获取成功");
    }
    
    //创建新的队列
    error = AudioQueueNewOutput(&aqData.mDataFormat, HandleOutputBuffer, &aqData, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &aqData.mQueue);
    if ([self checkError:error] == NO) {
        NSLog(@"队列创建失败");
        return;
    }else {
        NSLog(@"队列创建成功");
    }
    
    //得到最大包的大小
    UInt32 maxPacketSize;
    UInt32 propertySize = sizeof(maxPacketSize);
    error = AudioFileGetProperty(aqData.mAudioFile, kAudioFilePropertyPacketSizeUpperBound, &propertySize, &maxPacketSize);
    if ([self checkError:error] == NO) {
        NSLog(@"取最大包大小失败");
        return;
    }else {
        NSLog(@"最大包大小为：%zd",maxPacketSize);
    }
    //计算buffer size大小
    DeriveBufferSize(aqData.mDataFormat, maxPacketSize, 0.5, &aqData.bufferByteSize, &aqData.mNumPacketsToRead);
    
    
    bool isFormatVBR = (aqData.mDataFormat.mBytesPerPacket == 0 ||aqData.mDataFormat.mFramesPerPacket == 0);
    
    if (isFormatVBR) {
        aqData.mPacketDescs =(AudioStreamPacketDescription*) malloc (aqData.mNumPacketsToRead * sizeof (AudioStreamPacketDescription));
    } else {
        aqData.mPacketDescs = NULL;
    }
    
    aqData.mCurrentPacket = 0;
    //缓存
    for (int i = 0; i < kNumberBuffers; ++i) {
        error = AudioQueueAllocateBuffer(aqData.mQueue, aqData.bufferByteSize, &aqData.mBuffers[i]);
        if (error != NO) {
            NSLog(@"缓存失败");
            return;
        }else {
            NSLog(@"缓存成功");
        }
        HandleOutputBuffer(&aqData,aqData.mQueue,aqData.mBuffers[i]);
    }
    
    Float32 gain = 10.0;
    // Optionally, allow user to override gain setting here
    AudioQueueSetParameter (
                            aqData.mQueue,
                            kAudioQueueParam_Volume,
                            gain
                            );
    aqData.mIsRunning = true;
    AudioQueueStart(aqData.mQueue, NULL);
    
    printf("Playing...\n");
    
    //启动runLoop
    //方法1
    //    do {
    //        CFRunLoopRunInMode(kCFRunLoopDefaultMode,0.25,false);
    //    } while (aqData.mIsRunning);
    //方法2
    [[NSRunLoop currentRunLoop] run];
    
}

- (BOOL)checkError:(int)error {
    if (error == noErr) {
        return YES;
    }
    if (error == kAudioFileUnspecifiedError) {
        NSLog(@"kAudioFileUnspecifiedError");
    } else if(error == kAudioFileUnsupportedFileTypeError){
        NSLog(@"kAudioFileUnsupportedFileTypeError");
    }else if(error == kAudioFileUnsupportedDataFormatError){
        NSLog(@"kAudioFileUnsupportedDataFormatError");
    }else if(error == kAudioFileUnsupportedPropertyError){
        NSLog(@"kAudioFileUnsupportedPropertyError");
    }else if(error == kAudioFileBadPropertySizeError){
        NSLog(@"kAudioFileBadPropertySizeError");
    }else if(error == kAudioFilePermissionsError){
        NSLog(@"kAudioFilePermissionsError");
    }else if(error == kAudioFileNotOptimizedError){
        NSLog(@"kAudioFileNotOptimizedError");
    }else if(error == kAudioFileInvalidChunkError){
        NSLog(@"kAudioFileInvalidChunkError");
    }else if(error == kAudioFileDoesNotAllow64BitDataSizeError){
        NSLog(@"kAudioFileDoesNotAllow64BitDataSizeError");
    }else if(error == kAudioFileInvalidPacketOffsetError){
        NSLog(@"kAudioFileInvalidPacketOffsetError");
    }else if(error == kAudioFileInvalidFileError){
        NSLog(@"kAudioFileInvalidFileError");
    }else if(error == kAudioFileOperationNotSupportedError){
        NSLog(@"kAudioFileOperationNotSupportedError");
    }else if(error == kAudioFileNotOpenError){
        NSLog(@"kAudioFileNotOpenError");
    }else if(error == kAudioFileEndOfFileError){
        NSLog(@"kAudioFileEndOfFileError");
    }else if(error == kAudioFilePositionError){
        NSLog(@"kAudioFilePositionError");
    }else if(error == kAudioFileFileNotFoundError){
        NSLog(@"kAudioFileFileNotFoundError");
    }
    
    return NO;
}



@end
