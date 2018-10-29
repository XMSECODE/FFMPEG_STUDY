//
//  ESCMediaInfoModel.h
//  FFMPEG_STUDY
//
//  Created by xiang on 2018/10/29.
//  Copyright © 2018 XMSECODE. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ESCMediaInfoModel : NSObject

@property(nonatomic,assign)int videoFrameRate;

@property(nonatomic,assign)int videoWidth;

@property(nonatomic,assign)int videoHeight;

@end

NS_ASSUME_NONNULL_END
