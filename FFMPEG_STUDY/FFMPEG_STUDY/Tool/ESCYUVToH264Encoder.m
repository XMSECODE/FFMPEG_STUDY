//
//  ESCYUVToH264Encoder.m
//  FFMPEG_STUDY
//
//  Created by xiang on 2018/8/2.
//  Copyright © 2018年 XMSECODE. All rights reserved.
//

#import "ESCYUVToH264Encoder.h"
#import "x264.h"

//enum nal_unit_type_e {
//    NAL_UNKNOWN     = 0,    // 未使用
//    NAL_SLICE       = 1,    // 不分区、非 IDR 图像的片
//    NAL_SLICE_DPA   = 2,    // 片分区 A
//    NAL_SLICE_DPB   = 3,    // 片分区 B
//    NAL_SLICE_DPC   = 4,    // 片分区 C
//    NAL_SLICE_IDR   = 5,    /* ref_idc != 0 */  // 序列参数集
//    NAL_SEI         = 6,    /* ref_idc == 0 */  // 图像参数集
//    NAL_SPS         = 7,    // 分界符
//    NAL_PPS         = 8,    // 序列结束
//    NAL_AUD         = 9,    // 码流结束
//    NAL_FILLER      = 12,   // 填充
//    /* ref_idc == 0 for 6,9,10,11,12 */
//};
//enum nal_priority_e // 优先级
//{
//    NAL_PRIORITY_DISPOSABLE = 0,
//    NAL_PRIORITY_LOW        = 1,
//    NAL_PRIORITY_HIGH       = 2,
//    NAL_PRIORITY_HIGHEST    = 3,
//};

typedef struct
{
    int startcodeprefix_len;      //! 4 for parameter sets and first slice in picture, 3 for everything else (suggested)
    unsigned len;                 //! Length of the NAL unit (Excluding the start code, which does not belong to the NALU)
    unsigned max_size;            //! Nal Unit Buffer size
    int forbidden_bit;            //! should be always FALSE
    int nal_reference_idc;        //! NALU_PRIORITY_xxxx
    int nal_unit_type;            //! NALU_TYPE_xxxx
    char *buf;                    //! contains the first byte followed by the EBSP
} NALU_t;

@interface ESCYUVToH264Encoder ()

@property(nonatomic,assign)x264_t *x264Handle;

@property(nonatomic,assign)x264_nal_t* pNals;

@property(nonatomic,assign)x264_picture_t pic_out;

@property(nonatomic,assign)x264_picture_t pic_in;

@property(nonatomic,assign)FILE *fp_dst;

@property(nonatomic,assign)NSInteger frameCount;

@property(nonatomic,assign)int y_size;

@end

@implementation ESCYUVToH264Encoder

- (instancetype)init {
    self = [super init];
    if (self) {
        self.spsAndPpsIsIncludedInIframe = YES;
    }
    return self;
}

+ (void)yuvToH264EncoderWithVideoWidth:(NSInteger)width
                                height:(NSInteger)height
                           yuvFilePath:(NSString *)yuvFilePath
                          h264FilePath:(NSString *)h264FilePath
                             frameRate:(NSInteger)frameRate {
    const char* pathchar = [yuvFilePath cStringUsingEncoding:NSUTF8StringEncoding];
    
    FILE *fp=fopen(pathchar,"rb");
    if (fp == NULL) {
        NSLog(@"打开文件失败");
        return;
    }
    
    x264_t *x264Handle = NULL;

    [self x264_encode_init:&x264Handle width:width height:height frameRate:frameRate];
    
    unsigned char *yuv420data=(unsigned char *)malloc(width * height * 2);
    
    int csp=X264_CSP_I420;

    x264_picture_t pic_out;
    x264_picture_init(&pic_out);
    x264_picture_alloc(&pic_out, csp, (int)width, (int)height);
    
    x264_picture_t pic_in;
    x264_picture_init(&pic_in);
    x264_picture_alloc(&pic_in, csp, (int)width, (int)height);
    
    int y_size = (int)width * (int)height;

    int frameCount = 0;
    x264_nal_t* pNals = NULL;

    const char *outchar = [h264FilePath cStringUsingEncoding:NSUTF8StringEncoding];

    FILE* fp_dst = fopen(outchar, "a+");

    if (fp_dst == NULL) {
        NSLog(@"打开目标文件失败");
        return;
    }
    
    while(fread(yuv420data,width * height * 3 / 2,1,fp) > 0){
        int iNal   = 0;
        
        memcpy(pic_in.img.plane[0], yuv420data, y_size); //y
        memcpy(pic_in.img.plane[1], yuv420data  + y_size, y_size/4); //u
        memcpy(pic_in.img.plane[2], yuv420data  + y_size + y_size/4, y_size/4); //v
        
        pic_out.i_pts = frameCount;
        frameCount++;
        int ret = x264_encoder_encode(x264Handle, &pNals, &iNal, &pic_in, &pic_out);
        
        printf("encoder start! %5d\n",frameCount);

        if (ret <= 0){
            continue;
        }
        
        if (iNal <= 0) {
            continue;
        }
        
        int j = 0;
        
        for ( j = 0; j < iNal; ++j){
            fwrite(pNals[j].p_payload, pNals[j].i_payload, 1, fp_dst);
            printf("encoder succeed!====%d===%d\n",iNal,pNals[j].i_payload);
        }
    }

    while (1) {
        int iNal   = 0;
        pic_out.i_pts = frameCount;
        frameCount++;
        
        int ret = x264_encoder_encode(x264Handle, &pNals, &iNal, NULL, &pic_out);
        NSLog(@"encoder start!");
        if (ret <= 0){
            printf("Error.\n");
            break;
        }
       
        int j = 0;
        
        for ( j = 0; j < iNal; ++j){
            fwrite(pNals[j].p_payload, pNals[j].i_payload, 1, fp_dst);
            printf("encoder succeed!====%d===%d\n",iNal,pNals[j].i_payload);
        }
    }
    
    fclose(fp_dst);

    x264_picture_clean(&pic_in);
    
    x264_encoder_close(x264Handle);

    free(yuv420data);
    fclose(fp);
}

+ (void)x264_encode_init:(x264_t **)pHandle
                   width:(NSInteger)width
                  height:(NSInteger)height
               frameRate:(NSInteger)frameRate{
    
    x264_param_t param;
    x264_param_default(&param);
    //设置即时编码
    x264_param_default_preset(&param, "fast" , "zerolatency" );
    param.i_width   = (int)width;
    param.i_height  = (int)height;
    //设置b帧为0，不生成b帧
    param.i_bframe = 0;
    //设置i帧间隔
    param.i_fps_num = (int)frameRate;
    param.i_fps_den = 1;
    param.i_keyint_max = (int)frameRate * 2;
    // 重复SPS/PPS 放到关键帧前面
     param.b_repeat_headers = 1;
    //色彩空间 YUV420P
    param.i_csp=X264_CSP_I420;
    //profile设置
    x264_param_apply_profile(&param, x264_profile_names[0]);
    *pHandle = x264_encoder_open(&param);
    //日志打印等级
//    param.i_log_level  = X264_LOG_DEBUG;

    /*
     参数设置相关
     //https://blog.csdn.net/zhumengduan3526/article/details/78707021
     //Param
     param.i_threads  = X264_SYNC_LOOKAHEAD_AUTO;
     param.i_frame_total = 0;
     param->i_keyint_max = 10;
     param->i_bframe  = 5;
     param->b_open_gop  = 0;
     param->i_bframe_pyramid = 0;
     param->rc.i_qp_constant=0;
     param->rc.i_qp_max=0;
     param->rc.i_qp_min=0;
     param->i_bframe_adaptive = X264_B_ADAPT_TRELLIS;
     param->i_fps_den  = 1;
     param->i_fps_num  = 25;
     param->i_timebase_den = param->i_fps_num;
     param->i_timebase_num = param->i_fps_den;
     */
    
}

- (void)setupVideoWidth:(NSInteger)width
                 height:(NSInteger)height
              frameRate:(NSInteger)frameRate
           h264FilePath:(NSString *)h264FilePath {
    
    x264_t *x264Handle = NULL;
    
    [ESCYUVToH264Encoder x264_encode_init:&x264Handle width:width height:height frameRate:frameRate];
    
    int csp=X264_CSP_I420;
    
    x264_picture_init(&_pic_in);
    x264_picture_alloc(&_pic_in, csp, (int)width, (int)height);
    
    self.y_size = (int)width * (int)height;
    
    self.frameCount = 0;
    
    self.pNals = NULL;
    
    const char *outchar = [h264FilePath cStringUsingEncoding:NSUTF8StringEncoding];
    
    FILE* fp_dst = fopen(outchar, "a+");
    
    if (fp_dst == NULL) {
        NSLog(@"打开目标文件失败");
        return;
    }
    self.fp_dst = fp_dst;
    
    self.x264Handle = x264Handle;
}

- (void)setupVideoWidth:(NSInteger)width
                 height:(NSInteger)height
              frameRate:(NSInteger)frameRate
               delegate:(id<ESCYUVToH264EncoderDelegate>)delegate {
    
    if (delegate) {
        self.delegate = delegate;
    }else {
        return;
    }
    
    x264_t *x264Handle = NULL;
    
    [ESCYUVToH264Encoder x264_encode_init:&x264Handle width:width height:height frameRate:frameRate];
    
    int csp=X264_CSP_I420;
    
    
    x264_picture_init(&_pic_out);
    x264_picture_alloc(&_pic_out, csp, (int)width, (int)height);
    
    x264_picture_init(&_pic_in);
    x264_picture_alloc(&_pic_in, csp, (int)width, (int)height);
    
    self.y_size = (int)width * (int)height;
    
    self.frameCount = 0;
    
    self.pNals = NULL;
    
    self.x264Handle = x264Handle;
    
}

- (void)encoderYUVData:(NSData *)yuvData {
    
    NSLog(@"开始编码YUV数据");
    const unsigned char *yuv420data = [yuvData bytes];
    
    int iNal   = 0;
    
    memcpy(_pic_in.img.plane[0], yuv420data, self.y_size); //y
    memcpy(_pic_in.img.plane[1], yuv420data  + self.y_size, self.y_size/4); //u
    memcpy(_pic_in.img.plane[2], yuv420data  + self.y_size + self.y_size/4, self.y_size/4); //v
    
    _pic_in.i_pts = self.frameCount;
    self.frameCount++;
    int ret = x264_encoder_encode(self.x264Handle, &_pNals, &iNal, &_pic_in, &_pic_out);
    
    if (ret <= 0){
        return;
    }
    
    if (iNal <= 0) {
        return;
    }
    
    [self readH264DataWithNal:iNal];
}

- (void)readH264DataWithNal:(int)iNal {

    if (_fp_dst != NULL) {
        for (int j = 0; j < iNal; ++j){
            fwrite(_pNals[j].p_payload, _pNals[j].i_payload, 1, _fp_dst);
        }
    }
    NSLog(@"YUV数据编码完成");
    if (self.spsAndPpsIsIncludedInIframe == YES) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(encoder:h264Data:dataLenth:)]) {
            int length = 0;
            //统计数据长度
            for (int j = 0; j < iNal; ++j){
                length += _pNals[j].i_payload;
                if (_pNals[j].p_payload[2] == 0x01) {
                    length++;
                }
            }
            
            char *temdata = malloc(length);
            int lastIndex = 0;
            //拼接数据
            for (int j = 0; j < iNal; ++j){
                if (_pNals[j].p_payload[2] == 0x01) {
                    temdata[lastIndex] = 0x0;
                    lastIndex++;
                }
                memcpy(temdata + lastIndex, _pNals[j].p_payload, _pNals[j].i_payload);
                lastIndex += _pNals[j].i_payload;
            }
            //发送数据
            [self.delegate encoder:self h264Data:temdata dataLenth:length];
            //释放空间
            free(temdata);
        }
    }else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(encoder:h264Data:dataLenth:)]) {
            for (int j = 0; j < iNal; ++j){
                if (_pNals[j].p_payload[2] == 0x01) {
                    char *temdata = malloc(_pNals[j].i_payload + 1);
                    temdata[0] = 0;
                    memcpy(temdata + 1, _pNals[j].p_payload, _pNals[j].i_payload);
                    [self.delegate encoder:self h264Data:temdata dataLenth:_pNals[j].i_payload + 1];
                    free(temdata);
                }else {
                    //直接发送数据
                    [self.delegate encoder:self h264Data:_pNals[j].p_payload dataLenth:_pNals[j].i_payload];
                }
            }
        }
    }
}

-(void)endYUVDataStream {
    while (1) {
        int iNal   = 0;
        self.frameCount++;
        
        int ret = x264_encoder_encode(_x264Handle, &_pNals, &iNal, NULL, &_pic_out);
        if (ret <= 0){
            printf("Error. no h264 data!\n");
            break;
        }
                
        [self readH264DataWithNal:iNal];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(encoderEnd:)]) {
        [self.delegate encoderEnd:self];
    }
    
    if (_fp_dst != NULL) {
        fclose(_fp_dst);
    }
    
    x264_picture_clean(&_pic_in);
    
    x264_encoder_close(_x264Handle);
    
}

@end

