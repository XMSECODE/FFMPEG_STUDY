//
//  ESCAACToPCMDecoder.h
//  FFMPEG_STUDY
//
//  Created by xiang on 2018/7/18.
//  Copyright © 2018年 XMSECODE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "avcodec.h"

@interface ESCAACToPCMDecoder : NSObject

+ (AVFrame *)getPCMAVFrameFromOtherFormat:(AVFrame *)frame;

@end
