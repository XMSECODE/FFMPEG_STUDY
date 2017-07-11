//
//  ECOpenGLView.m
//  FFMPEG_STUDY
//
//  Created by xiangmingsheng on 2017/6/25.
//  Copyright © 2017年 XMSECODE. All rights reserved.
//

#import "ECOpenGLView.h"
#import "Header.h"
#import <CoreGraphics/CoreGraphics.h>
#import "ECSwsscaleManager.h"

@interface ECOpenGLView ()

@property(nonatomic,strong)UIImage* image;

@end

@implementation ECOpenGLView

- (void)drawRect:(CGRect)rect {
    [self.image drawInRect:rect];
}

- (void)setAvFrame:(AVFrame *)avFrame {
    UIImage *image = [ECSwsscaleManager getImageFromAVFrame:avFrame];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"image == %@",image);
        self.image = image;
        [self setNeedsDisplay];
    });
}


@end
