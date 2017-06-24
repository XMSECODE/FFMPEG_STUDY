//
//  UIView+XMSView.m
//  lotteryApp
//
//  Created by xiangmingsheng on 16/8/20.
//  Copyright © 2016年 xiangmingsheng. All rights reserved.
//

#import "UIView+XMSView.h"

@implementation UIView (XMSView)

#pragma mark - 开始对控件的frame进行赋值与取值
-(void)setY:(CGFloat)Y{
    CGRect temframe = self.frame;
    temframe.origin.y = Y;
    self.frame = temframe;
}
-(CGFloat)Y{
    return  self.frame.origin.y;
}

-(void)setX:(CGFloat)X{
    CGRect temframe = self.frame;
    temframe.origin.x = X;
    self.frame = temframe;
}
-(CGFloat)X{
    return  self.frame.origin.x;
}

-(void)setW:(CGFloat)W{
    CGRect temframe = self.frame;
    temframe.size.width = W;
    self.frame = temframe;
}
-(CGFloat)W{
    return  self.frame.size.width;
}

-(void)setH:(CGFloat)H{
    CGRect temframe = self.frame;
    temframe.size.height = H;
    self.frame = temframe;
}
-(CGFloat)H{
    return  self.frame.size.height;
}

- (CGFloat)centerX {
    return self.center.x;
}

- (void)setCenterX:(CGFloat)centerX {
    CGPoint center = self.center;
    center.x = centerX;
    self.center = center;
}

- (CGFloat)centerY {
    return self.center.y;
}

- (void)setCenterY:(CGFloat)centerY {
    CGPoint center = self.center;
    center.y = centerY;
    self.center = center;
}

@end
