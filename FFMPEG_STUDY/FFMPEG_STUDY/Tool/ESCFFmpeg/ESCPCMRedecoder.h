//
//  ESCAACToPCMDecoder.h
//  FFMPEG_STUDY
//
//  Created by xiang on 2018/7/18.
//  Copyright © 2018年 XMSECODE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "avcodec.h"

@interface ESCPCMRedecoder : NSObject

- (void)initConvertWithFrame:(AVFrame *)frame;

- (AVFrame *)getPCMAVFrameFromOtherFormat:(AVFrame *)frame;

- (void)freeAudioFrame:(AVFrame *)audioFrame;

- (void)destroy;

@end
