//
//  ESCYUVToH264Encoder.h
//  FFMPEG_STUDY
//
//  Created by xiang on 2018/8/2.
//  Copyright © 2018年 XMSECODE. All rights reserved.
//

#import <Foundation/Foundation.h>

void yuvCodecToVideoH264(const char *input_file_name);

@interface ESCYUVToH264Encoder : NSObject

+ (void)yuvToH264EncoderWithVideoWidth:(NSInteger)width height:(NSInteger)height yuvFilePath:(NSString *)yuvFilePath h264FilePath:(NSString *)h264FilePath frameRate:(NSInteger)frameRate;

@end
