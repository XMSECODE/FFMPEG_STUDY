//
//  H264ToMp4.h
//  MTLiveStreamingKit
//
//  Created by 包红来 on 2017/6/16.
//  Copyright © 2017年 LGW. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define NAL_SLICE 1
#define NAL_SLICE_DPA 2
#define NAL_SLICE_DPB 3
#define NAL_SLICE_DPC 4
#define NAL_SLICE_IDR 5
#define NAL_SEI 6
#define NAL_SPS 7
#define NAL_PPS 8
#define NAL_AUD 9
#define NAL_FILLER 12

typedef struct _NaluUnit
{
    int type; //IDR or INTER：note：SequenceHeader is IDR too
    int size; //note: don't contain startCode
    unsigned char *data; //note: don't contain startCode
} NaluUnit;

@interface ESCH264StreamToMp4FileTool : NSObject

/**
 初始化工具对象
 */
- (instancetype)initWithVideoSize:(CGSize)videoSize
                         filePath:(NSString *)filePath
                        frameRate:(NSInteger)frameRate;

/**
 写入h264数据
 */
- (void)pushH264DataContentSpsAndPpsData:(NSData *)h264Data;

/**
 结束写入
 */
- (void)endWritingCompletionHandler:(void (^)(void))handler;

@end
