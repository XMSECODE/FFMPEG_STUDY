//
//  ESCOpenGLESView.h
//  ESCOpenGLESShowImageDemo
//
//  Created by xiang on 2018/7/25.
//  Copyright © 2018年 xiang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ESCOpenGLESView : UIView

- (void)loadImage:(UIImage *)image;

- (void)loadRGBData:(void *)data lenth:(NSInteger)lenth width:(NSInteger)width height:(NSInteger)height;

@end
