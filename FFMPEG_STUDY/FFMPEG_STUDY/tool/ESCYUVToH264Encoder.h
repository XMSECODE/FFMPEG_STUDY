//
//  ESCYUVToH264Encoder.h
//  FFMPEG_STUDY
//
//  Created by xiang on 2018/8/2.
//  Copyright © 2018年 XMSECODE. All rights reserved.
//

#import <Foundation/Foundation.h>

void yuvCodecToVideoH264(const char *input_file_name);

@class ESCYUVToH264Encoder;

@protocol ESCYUVToH264EncoderDelegate<NSObject>

- (void)encoder:(ESCYUVToH264Encoder*)encoder h264Data:(void *)h264Data dataLenth:(NSInteger)lenth;

- (void)encoderEnd:(ESCYUVToH264Encoder *)encoder;

@end

@interface ESCYUVToH264Encoder : NSObject

+ (void)yuvToH264EncoderWithVideoWidth:(NSInteger)width height:(NSInteger)height yuvFilePath:(NSString *)yuvFilePath h264FilePath:(NSString *)h264FilePath frameRate:(NSInteger)frameRate;

@property(nonatomic,weak)id delegate;

- (void)setupVideoWidth:(NSInteger)width height:(NSInteger)height frameRate:(NSInteger)frameRate h264FilePath:(NSString *)h264FilePath;

- (void)setupVideoWidth:(NSInteger)width height:(NSInteger)height frameRate:(NSInteger)frameRate delegate:(id<ESCYUVToH264EncoderDelegate>)delegate;

- (void)encoderYUVData:(NSData *)yuvData;

-(void)endYUVDataStream;

@end
