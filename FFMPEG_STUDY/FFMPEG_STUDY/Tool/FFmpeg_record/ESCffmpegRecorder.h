//
//  ESCffmpegRecorder
//  CloudViews
//
//  Created by xiang on 2018/8/9.
//  Copyright © 2018年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ESCffmpegRecorder : NSObject

+ (instancetype)recordFileWithFilePath:(NSString *)filePath
                             codecType:(NSInteger)codecType
                            videoWidth:(NSInteger)videoWidth
                           videoHeight:(NSInteger)videoHeight
                        videoFrameRate:(NSInteger)videoFrameRate;

+ (instancetype)recordFileWithFilePath:(NSString *)filePath
                             codecType:(NSInteger)codecType
                            videoWidth:(NSInteger)videoWidth
                           videoHeight:(NSInteger)videoHeight
                        videoFrameRate:(NSInteger)videoFrameRate
                     audioSampleFormat:(NSInteger)audioSampleFormat
                       audioSampleRate:(NSInteger)audioSampleRate
                    audioChannelLayout:(NSInteger)audioChannelLayout
                         audioChannels:(NSInteger)audioChannels;

- (void)writeVideoFrame:(void *)data length:(NSInteger)length;

- (void)writeAudioFrame:(void *)data length:(NSInteger)length;

- (void)stopRecord;

@end
