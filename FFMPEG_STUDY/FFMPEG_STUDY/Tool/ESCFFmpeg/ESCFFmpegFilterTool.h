//
//  ESCFFmpegFilterTool.h
//  FFMPEG_STUDY
//
//  Created by xiang on 2019/4/10.
//  Copyright © 2019 XMSECODE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "avformat.h"

@interface ESCFFmpegFilterTool : NSObject

- (BOOL)setupWithWidth:(int)width
                height:(int)height
           pixelFormat:(enum AVPixelFormat)pixelFormat
             time_base:(AVRational)time_base
   sample_aspect_ratio:(AVRational)sample_aspect_ratio
          filter_descr:(NSString *)filter_descr;

- (AVFrame *)filterFrame:(AVFrame *)frame;

- (void)destroy;

@end

