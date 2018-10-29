//
//  ESCFrameDataModel.h
//  FFMPEG_STUDY
//
//  Created by xiang on 2018/10/29.
//  Copyright © 2018 XMSECODE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "avformat.h"

typedef enum : NSUInteger {
    ESCFrameDataModelTypeVideoFrame,
    ESCFrameDataModelTypeAudioFrame,
    ESCFrameDataModelTypeVideoPacket,
    ESCFrameDataModelTypeAudioPacket,
} ESCFrameDataModelType;

NS_ASSUME_NONNULL_BEGIN

@interface ESCFrameDataModel : NSObject

@property(nonatomic,assign)ESCFrameDataModelType type;

@property(nonatomic,assign)AVFrame *frame;

@property(nonatomic,assign)AVPacket *packet;

@end

NS_ASSUME_NONNULL_END
