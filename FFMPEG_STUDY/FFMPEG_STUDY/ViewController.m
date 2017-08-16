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
@property (nonatomic, assign) AudioQueueRef *queue;
@property (nonatomic, assign) BOOL isFailure;

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
    
//    self.i = 0;
    
//    self.streamQueue = [[NSOperationQueue alloc] init];
//    self.streamQueue.maxConcurrentOperationCount = 1;
    
    
//    [self initAudioStreamQueue];
    
    [self playWithImageViewWithURLString:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
    
//    [self setupView];
    
    //    [self getFirstFrameWithURLString:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
    
    //    [self getFirstFrameWithURLString:@"/Users/xiangmingsheng/Music/网易云音乐/Bridge - 雾都历.mp3"];
    
    //    [self getAudioFrameWithURLString:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
    
    //    [self playAudioWithURLString:@"/Users/xiangmingsheng/Music/网易云音乐/Bridge - 雾都历.mp3"];
    
    //    [self getAudioFrameWithURLString:@"rtmp://live.hkstv.hk.lxdns.com/live/hks"];
    
    
    //    self.playThread = [[NSThread alloc] initWithTarget:self selector:@selector(playMusic) object:nil];
    
    
    //    [self.playThread start];
    
    
}

- (void)initAudioStreamQueue {
    AudioFileStreamID streamID = NULL;
    int code = AudioFileStreamOpen((__bridge void * _Nullable)(self), func1_AudioFileStream_PropertyListenerProc, func2_AudioFileStream_PacketsProc,kAudioFileAAC_ADTSType, &streamID);
    if (code == 0) {
        self.streamID = streamID;
        printf("init Audio Stream success\n");
    }else {
        printf("init Audio Stream failure\n");
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

void my_AudioQueueOutputCallback(void * __nullable       inUserData,
                                 AudioQueueRef           inAQ,
                                 AudioQueueBufferRef     inBuffer) {
    printf("my_AudioQueueOutputCallback");
};

void  func1_AudioFileStream_PropertyListenerProc(void *							inClientData,
                                                 AudioFileStreamID				inAudioFileStream,
                                                 AudioFileStreamPropertyID		inPropertyID,
                                                 AudioFileStreamPropertyFlags *	ioFlags) {
    if (inPropertyID ==  kAudioFileStreamProperty_DataFormat) {
        UInt32 outDataSize = sizeof(AudioStreamBasicDescription);
        AudioStreamBasicDescription *audiostream = NULL;
        AudioStreamBasicDescription audios;
        int s = kAudioFormatMPEG4AAC;
        NSLog(@"%d",s);
        audiostream = &audios;
        int code = AudioFileStreamGetProperty(inAudioFileStream, inPropertyID, &outDataSize, audiostream);
        NSLog(@"%f",audios.mSampleRate);
        printf("mSampleRate = %f  mFormatID = %u  mFormatFlags = %d  mBytesPerPacket = %d mFramesPerPacket = %d  mBytesPerFrame = %d  mChannelsPerFrame = %d  mBitsPerChannel = %d  mReserved = %d\n",audiostream->mSampleRate,(unsigned int)audiostream->mFormatID,audiostream->mFormatFlags,audiostream->mBytesPerPacket,audiostream->mFramesPerPacket,audiostream->mBytesPerFrame,audiostream->mChannelsPerFrame,audiostream->mBitsPerChannel,audiostream->mReserved);
        if (code == noErr) {
            AudioQueueRef queueRef;
            AudioQueueRef *queue = &queueRef;
            audiostream->mSampleRate = 48000;
//            audiostream->mFormatID = kAudioFormatMPEG4AAC_LD;
//            audiostream->mFormatFlags = 0;
//            audiostream->mBytesPerPacket =
            audiostream->mBitsPerChannel = 8;
            audiostream->mChannelsPerFrame = 3;
            audiostream->mBytesPerFrame      = audiostream->mBitsPerChannel * audiostream->mChannelsPerFrame/8;//每帧的bytes数
            audiostream->mBytesPerPacket     = audiostream->mBytesPerFrame * audiostream->mFramesPerPacket;//每个数据包的bytes总数，每帧的bytes数＊每个数据包的帧数
            
            printf("mSampleRate = %f  mFormatID = %u  mFormatFlags = %d  mBytesPerPacket = %d mFramesPerPacket = %d  mBytesPerFrame = %d  mChannelsPerFrame = %d  mBitsPerChannel = %d  mReserved = %d\n",audiostream->mSampleRate,(unsigned int)audiostream->mFormatID,audiostream->mFormatFlags,audiostream->mBytesPerPacket,audiostream->mFramesPerPacket,audiostream->mBytesPerFrame,audiostream->mChannelsPerFrame,audiostream->mBitsPerChannel,audiostream->mReserved);

            printf("read audio stream basic description success\n");

            code =  AudioQueueNewOutput(audiostream, my_AudioQueueOutputCallback, inClientData, NULL, NULL, 0, queue);
            ViewController *view = (__bridge ViewController *)(inClientData);
            view.queue = queue;
            if (code == noErr) {
                printf("queue success\n");
            }else {
                printf("queue failure == %d\n",code);
            }
        }else {
            printf("read audio stream basic description failuren == %d\n",code);
        }
    }else if (inPropertyID == kAudioFileStreamProperty_ReadyToProducePackets) {
        printf("kAudioFileStreamProperty_ReadyToProducePackets\n");
    }else if (inPropertyID == kAudioFileStreamProperty_BitRate) {
        uint32_t bitRate;
        uint32_t bitRateSize = sizeof(bitRate);
        int code = AudioFileStreamGetProperty(inAudioFileStream, inPropertyID, &bitRateSize, &bitRate);
        if (code == noErr) {
            printf("read audio bitRate success %d/n",bitRate);
        }else {
            printf("read audio bitRate failure = %d\n",code);
        }
        printf("kAudioFileStreamProperty_BitRate\n");
    }else if (inPropertyID == kAudioFileStreamProperty_DataOffset) {
        printf("kAudioFileStreamProperty_DataOffset\n");
    }
       else if (inPropertyID == kAudioFileStreamProperty_FormatList) {
        //获取数据大小
        Boolean outWriteable;
        UInt32 formatListSize;
        OSStatus status = AudioFileStreamGetPropertyInfo(inAudioFileStream, kAudioFileStreamProperty_FormatList, &formatListSize, &outWriteable);
        if (status != noErr)
        {
            //错误处理
        }
        
        //获取formatlist
        AudioFormatListItem *formatList = malloc(formatListSize);
        status = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_FormatList, &formatListSize, formatList);
        if (status != noErr)
        {
            //错误处理
        }
        
        //选择需要的格式
        for (int i = 0; i * sizeof(AudioFormatListItem) < formatListSize; i += sizeof(AudioFormatListItem))
        { 
            AudioStreamBasicDescription pasbd = formatList[i].mASBD; 
            //选择需要的格式。。                              
        } 
        free(formatList);
    }
    printf("func1 %d\n",inPropertyID);

}

void func2_AudioFileStream_PacketsProc(void *							inClientData,
                                       UInt32							inNumberBytes,
                                       UInt32							inNumberPackets,
                                       const void *					inInputData,
                                       AudioStreamPacketDescription	*inPacketDescriptions) {
//    printf("func2\n");
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
            if (self.isFailure == NO) {
                int code = AudioFileStreamParseBytes(self.streamID, frame->linesize[0], frame->data[0], 0);
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
