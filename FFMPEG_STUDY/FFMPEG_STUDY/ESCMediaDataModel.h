//
//  ESCMediaDataModel.h
//  FFMPEG_STUDY
//
//  Created by xiangmingsheng on 2018/7/31.
//  Copyright © 2018年 XMSECODE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ESCMediaDataModel : NSObject

@property(nonatomic,assign)NSInteger type;

@property(nonatomic,strong)NSData* audioData;

@property(nonatomic,strong)NSData* yData;

@property(nonatomic,strong)NSData* uData;

@property(nonatomic,strong)NSData* vData;

@property(nonatomic,assign)NSInteger pts;

@end
