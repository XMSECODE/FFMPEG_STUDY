//
//  ESCYUVToH264Encoder.h
//  FFMPEG_STUDY
//
//  Created by xiang on 2018/8/2.
//  Copyright © 2018年 XMSECODE. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ESCYUVToH264Encoder;

@protocol ESCYUVToH264EncoderDelegate<NSObject>

/**
 压缩后的h264数据流
 */
- (void)encoder:(ESCYUVToH264Encoder*)encoder h264Data:(void *)h264Data dataLenth:(NSInteger)lenth;

/**
 压缩结束
 */
- (void)encoderEnd:(ESCYUVToH264Encoder *)encoder;

@end

@interface ESCYUVToH264Encoder : NSObject

@property(nonatomic,weak)id delegate;

//sps和pps数据是否包含在关键帧前面，默认为YES
@property(nonatomic,assign)BOOL spsAndPpsIsIncludedInIframe;


/**
 yuv文件转h264压缩文件
 */
+ (void)yuvToH264EncoderWithVideoWidth:(NSInteger)width
                                height:(NSInteger)height
                           yuvFilePath:(NSString *)yuvFilePath
                          h264FilePath:(NSString *)h264FilePath
                             frameRate:(NSInteger)frameRate;
/**
 yuv流转h264压缩文件
 */
- (void)setupVideoWidth:(NSInteger)width
                 height:(NSInteger)height
              frameRate:(NSInteger)frameRate
           h264FilePath:(NSString *)h264FilePath;
/**
 yuv流转h264流
 */
- (void)setupVideoWidth:(NSInteger)width
                 height:(NSInteger)height
              frameRate:(NSInteger)frameRate
               delegate:(id<ESCYUVToH264EncoderDelegate>)delegate;

/**
 填充需要压缩的yuv流数据
 */
- (void)encoderYUVData:(NSData *)yuvData;

/**
 yuv流数据接收完毕
 */
-(void)endYUVDataStream;

@end
