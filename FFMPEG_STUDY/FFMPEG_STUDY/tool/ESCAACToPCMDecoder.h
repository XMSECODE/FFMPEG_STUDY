//
//  ESCAACToPCMDecoder.h
//  FFMPEG_STUDY
//
//  Created by xiang on 2018/7/18.
//  Copyright © 2018年 XMSECODE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "avcodec.h"

void *aac_decoder_create(int sample_rate, int channels, int bit_rate);

int aac_decode_frame(void *pParam, unsigned char *pData, int nLen, unsigned char *pPCM, unsigned int *outLen,AVFrame *inputFrame);
    
void aac_decode_close(void *pParam);

@interface ESCAACToPCMDecoder : NSObject

@end
