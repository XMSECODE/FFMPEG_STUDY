//
//  ECSwsscaleManager.h
//  FFMPEG_STUDY
//
//  Created by xiangmingsheng on 2017/6/24.
//  Copyright © 2017年 XMSECODE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "avformat.h"

@interface ECSwsscaleManager : NSObject


/**
 下面两个方法会自动释放传入的frame
 */
+ (UIImage *)getImageFromAVFrame:(AVFrame *)frame;
+ (AVFrame *)getRGBAVFrameFromOtherFormat:(AVFrame *)frame;


/**
 保存AVFrame为PNG格式到本地，会转换为RGB24格式

 @param frame 需要保存的AVFrame
 @param filePath 文件路径
 */
+ (void)saveToPNGImageWithAVFrame:(AVFrame *)frame filePath:(NSString *)filePath success:(void(^)())success failure:(void(^)(NSError *error))failure;


@end
