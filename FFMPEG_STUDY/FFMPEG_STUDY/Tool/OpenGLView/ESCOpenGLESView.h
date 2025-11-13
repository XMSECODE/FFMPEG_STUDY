//
//  ESCOpenGLESView.h
//  ESCOpenGLESShowImageDemo
//
//  Created by xiang on 2018/7/25.
//  Copyright © 2018年 xiang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ESCType.h"

@interface ESCOpenGLESView : UIView

@property(nonatomic,assign)ESCVideoDataType type;

@property(nonatomic,assign)ESCOpenGLESViewShowType showType;

- (void)loadImage:(UIImage *)image;

- (void)loadRGBData:(void *)data lenth:(NSInteger)lenth width:(NSInteger)width height:(NSInteger)height;

- (void)loadYUV420PDataWithYData:(NSData *)yData uData:(NSData *)uData vData:(NSData *)vData width:(NSInteger)width height:(NSInteger)height;

- (void)destroy;

@end
