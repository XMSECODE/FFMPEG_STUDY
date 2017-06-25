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

@implementation ECOpenGLView

- (void)drawRect:(CGRect)rect {
//    if (self.avFrame == nil) {
//        return;
//    }
    
//    NSInteger height = self.avFrame->height;
//    NSInteger width = self.avFrame->width;
    
//    UIBezierPath *path = [UIBezierPath bezierPath];
//    path.lineWidth = 1;
//    for (int i = 0; i < height; i++) {
//        for (int j = 0; j < width; j++) {
//            int r = self.avFrame->data[0][i * width + width];
//            int g = self.avFrame->data[0][i * width + width + 1];
//            int b = self.avFrame->data[0][i * width + width + 2];
//            UIColor*color = kRGBColor(r, g, b);
//
//            if (i == 0 && j == 0) {
//                [path moveToPoint:CGPointMake(i, j)];
//            }else {
//                [path addLineToPoint:CGPointMake(i, j)];
//            }
//            if (i == height - 20 && j == width - 20) {
//                
//                self.backgroundColor = color;
//            }
//            [color setStroke];
//        }
//    }
//    [path stroke];
    
    
//    int r = self.avFrame->data[0][20 * width + width];
//    int g = self.avFrame->data[0][20 * width + width + 1];
//    int b = self.avFrame->data[0][20 * width + width + 2];
//    UIColor*color = kRGBColor(r, g, b);
//    self.backgroundColor = color;
}

- (void)setAvFrame:(AVFrame *)avFrame {
//    _avFrame = avFrame;
//    [self setNeedsDisplay];
}


@end
