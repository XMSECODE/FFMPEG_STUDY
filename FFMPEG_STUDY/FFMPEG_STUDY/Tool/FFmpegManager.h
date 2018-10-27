//
//  FFmpegManager.h
//  FFMPEG_STUDY
//
//  Created by xiangmingsheng on 2017/6/25.
//  Copyright © 2017年 XMSECODE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "avformat.h"

@interface FFmpegManager : NSObject

- (void)getFirstVideoFrameWithURL:(NSString *)urlString
                          success:(void(^)(AVFrame *firstFrame))success
                          failure:(void(^)(NSError *error))failure
                        decodeEnd:(void(^)(void))decodeEnd;

- (void)openAudioURL:(NSString *)urlString
        audioSuccess:(void(^)(AVFrame *frame,AVPacket *packet))audioSuccess
             failure:(void(^)(NSError *error))failure
           decodeEnd:(void(^)(void))decodeEnd;

- (void)openVideoURL:(NSString *)urlString
        videoSuccess:(void(^)(AVFrame *frame,AVPacket *packet))videoSuccess
             failure:(void(^)(NSError *error))failure
           decodeEnd:(void(^)(void))decodeEnd;

- (void)openURL:(NSString *)urlString
   videoSuccess:(void(^)(AVFrame *frame,AVPacket *packet))videoSuccess
   audioSuccess:(void(^)(AVFrame *frame,AVPacket *packet))audioSuccess
        failure:(void(^)(NSError *error))failure
      decodeEnd:(void(^)(void))decodeEnd;


- (void)openURL:(NSString *)urlString
        failure:(void(^)(NSError *error))failure;
- (void)readFrameVideoSuccess:(void(^)(AVFrame *frame,AVPacket *packet))videoSuccess
                 audioSuccess:(void(^)(AVFrame *frame,AVPacket *packet))audioSuccess
                      failure:(void(^)(NSError *error))failure
                    decodeEnd:(void(^)(void))decodeEnd;

- (void)stop;


@end
