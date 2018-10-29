//
//  FFmpegManager.h
//  FFMPEG_STUDY
//
//  Created by xiangmingsheng on 2017/6/25.
//  Copyright © 2017年 XMSECODE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESCFrameDataModel.h"
#import "ESCMediaInfoModel.h"

@interface ESCFFmpegFileTool : NSObject

- (void)openURL:(NSString *)urlString
        success:(void(^)(ESCMediaInfoModel *infoModel))success
        failure:(void(^)(NSError *error))failure;

- (void)readPacketVideoSuccess:(void(^)(ESCFrameDataModel *model))videoSuccess
                 audioSuccess:(void(^)(ESCFrameDataModel *model))audioSuccess
                      failure:(void(^)(NSError *error))failure
                    decodeEnd:(void(^)(void))decodeEnd;

- (void)decodePacket:(ESCFrameDataModel *)packet
       videoSuccess:(void(^)(ESCFrameDataModel *model))videoSuccess
       audioSuccess:(void(^)(ESCFrameDataModel *model))audioSuccess
            failure:(void(^)(NSError *error))failure;

- (void)stop;


@end
