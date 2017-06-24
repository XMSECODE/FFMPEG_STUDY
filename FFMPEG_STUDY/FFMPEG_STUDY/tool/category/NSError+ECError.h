//
//  NSError+ECError.h
//  FFMPEG_STUDY
//
//  Created by xiangmingsheng on 2017/6/24.
//  Copyright © 2017年 XMSECODE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (ECError)

+ (NSError *)EC_errorWithLocalizedDescription:(NSString *)localizedDescription;

@end
