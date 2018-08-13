//
//  NSError+ECError.m
//  FFMPEG_STUDY
//
//  Created by xiangmingsheng on 2017/6/24.
//  Copyright © 2017年 XMSECODE. All rights reserved.
//

#import "NSError+ECError.h"

@implementation NSError (ECError)

+ (NSError *)EC_errorWithLocalizedDescription:(NSString *)localizedDescription {
    NSError *error = [NSError errorWithDomain:@"" code:-1 userInfo:@{NSLocalizedDescriptionKey:localizedDescription}];
    return error;
}

@end
