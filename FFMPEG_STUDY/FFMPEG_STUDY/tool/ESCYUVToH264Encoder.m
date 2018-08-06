//
//  ESCYUVToH264Encoder.m
//  FFMPEG_STUDY
//
//  Created by xiang on 2018/8/2.
//  Copyright © 2018年 XMSECODE. All rights reserved.
//

#import "ESCYUVToH264Encoder.h"
#import "avformat.h"
#import "imgutils.h"
#import "x264.h"
//
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

+ (void)yuvToH264EncoderWithVideoWidth:(NSInteger)width height:(NSInteger)height yuvFilePath:(NSString *)yuvFilePath h264FilePath:(NSString *)h264FilePath frameRate:(NSInteger)frameRate {
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
        
        printf("Succeed encode frame: %5d\n",frameCount);
        
        if (ret <= 0){
            continue;
        }
        
        if (iNal <= 0) {
            continue;
        }
        
        int j = 0;
        
        for ( j = 0; j < iNal; ++j){
            fwrite(pNals[j].p_payload, pNals[j].i_payload, 1, fp_dst);
            printf("====%d===%d\n",iNal,pNals[j].i_payload);
        }
    }

    while (1) {
        int iNal   = 0;
        pic_out.i_pts = frameCount;
        frameCount++;
        
        int ret = x264_encoder_encode(x264Handle, &pNals, &iNal, NULL, &pic_out);
        if (ret <= 0){
            printf("Error.\n");
            break;
        }
       
        int j = 0;
        
        for ( j = 0; j < iNal; ++j){
            fwrite(pNals[j].p_payload, pNals[j].i_payload, 1, fp_dst);
            printf("====%d===%d\n",iNal,pNals[j].i_payload);
        }
    }
    
    fclose(fp_dst);

    x264_picture_clean(&pic_in);
    
    x264_encoder_close(x264Handle);

    free(yuv420data);
    fclose(fp);
}

+ (void)x264_encode_init:(x264_t **)pHandle width:(NSInteger)width height:(NSInteger)height frameRate:(NSInteger)frameRate{
    x264_param_t param;
    x264_param_default(&param);
    param.i_width   = (int)width;
    param.i_height  = (int)height;
//    param.i_fps_num = (int)frameRate;
//    param.i_fps_num = (int)(frameRate * 1000 + 0.5);
//    param.i_fps_den = 1000;
    /*
     //Param
     param.i_log_level  = X264_LOG_DEBUG;
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
    param.i_csp=X264_CSP_I420;
    x264_param_apply_profile(&param, x264_profile_names[6]);
    *pHandle = x264_encoder_open(&param);
}

- (void)setupVideoWidth:(NSInteger)width height:(NSInteger)height frameRate:(NSInteger)frameRate h264FilePath:(NSString *)h264FilePath {
    
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
    
    const char *outchar = [h264FilePath cStringUsingEncoding:NSUTF8StringEncoding];
    
    FILE* fp_dst = fopen(outchar, "a+");
    
    if (fp_dst == NULL) {
        NSLog(@"打开目标文件失败");
        return;
    }
    self.fp_dst = fp_dst;
    
    self.x264Handle = x264Handle;
}

- (void)setupVideoWidth:(NSInteger)width height:(NSInteger)height frameRate:(NSInteger)frameRate delegate:(id<ESCYUVToH264EncoderDelegate>)delegate {
    
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
    
    const unsigned char *yuv420data = [yuvData bytes];
    
    int iNal   = 0;
    
    memcpy(_pic_in.img.plane[0], yuv420data, self.y_size); //y
    memcpy(_pic_in.img.plane[1], yuv420data  + self.y_size, self.y_size/4); //u
    memcpy(_pic_in.img.plane[2], yuv420data  + self.y_size + self.y_size/4, self.y_size/4); //v
    
    _pic_out.i_pts = self.frameCount;
    self.frameCount++;
    int ret = x264_encoder_encode(self.x264Handle, &_pNals, &iNal, &_pic_in, &_pic_out);
    
    printf("Succeed encode frame: %5ld\n",(long)self.frameCount);
    
    if (ret <= 0){
        return;
    }
    
    if (iNal <= 0) {
        return;
    }
    
    if (_fp_dst != NULL) {
        for (int j = 0; j < iNal; ++j){
            fwrite(_pNals[j].p_payload, _pNals[j].i_payload, 1, _fp_dst);
        }
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(encoder:h264Data:dataLenth:)]) {
        for (int j = 0; j < iNal; ++j){
            [self.delegate encoder:self h264Data:_pNals[j].p_payload dataLenth:_pNals[j].i_payload];
        }
    }
    
}

-(void)endYUVDataStream {
    while (1) {
        int iNal   = 0;
        _pic_out.i_pts = self.frameCount;
        self.frameCount++;
        
        int ret = x264_encoder_encode(_x264Handle, &_pNals, &iNal, NULL, &_pic_out);
        if (ret <= 0){
            printf("Error.\n");
            break;
        }
                
        if (_fp_dst != NULL) {
            for (int j = 0; j < iNal; ++j){
                fwrite(_pNals[j].p_payload, _pNals[j].i_payload, 1, _fp_dst);
            }
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(encoder:h264Data:dataLenth:)]) {
            for (int j = 0; j < iNal; ++j){
                [self.delegate encoder:self h264Data:_pNals[j].p_payload dataLenth:_pNals[j].i_payload];
            }
        }
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






int flush_encoder(AVFormatContext *fmt_ctx,unsigned int stream_index){
    int ret;
    int got_frame;
    AVPacket enc_pkt;
    
    // 确认如果
    if (!(fmt_ctx->streams[stream_index]->codec->codec->capabilities &
          CODEC_CAP_DELAY))
        return 0;
    while (1) {
        enc_pkt.data = NULL;
        enc_pkt.size = 0;
        av_init_packet(&enc_pkt);
        ret = avcodec_encode_video2 (fmt_ctx->streams[stream_index]->codec, &enc_pkt,
                                     NULL, &got_frame);
        av_frame_free(NULL);
        if (ret < 0)
            break;
        if (!got_frame){
            ret=0;
            break;
        }
        printf("Flush Encoder: Succeed to encode 1 frame!/tsize:%5d/n",enc_pkt.size);
        /* mux encoded frame */
        ret = av_write_frame(fmt_ctx, &enc_pkt);
        if (ret < 0)
            break;
    }
    return ret;
}

void yuvCodecToVideoH264(const char *input_file_name) {
    FILE *in_file = fopen(input_file_name, "rb");
    // 因为我们在 iOS 工程当中，所以输出路径当然要设置本机的路径了
    const char* out_file = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"dash.h264"] cStringUsingEncoding:NSUTF8StringEncoding];
    
    // 注册 ffmpeg 中的所有的封装、解封装 和 协议等，当然，你也可用以下两个函数代替
    // * @see av_register_input_format()
    // * @see av_register_output_format()
    av_register_all();
    
    //  用作之后写入视频帧并编码成 h264，贯穿整个工程当中
    AVFormatContext* pFormatCtx;
    pFormatCtx = avformat_alloc_context();
    
    // 通过这个函数可以获取输出文件的编码格式, 那么这里我们的 fmt 为 h264 格式(AVOutputFormat *)
    AVOutputFormat *fmt = av_guess_format(NULL, out_file, NULL);
    pFormatCtx->oformat = fmt;
    
    // 打开文件的缓冲区输入输出，flags 标识为  AVIO_FLAG_READ_WRITE ，可读写
    if (avio_open(&pFormatCtx->pb,out_file, AVIO_FLAG_READ_WRITE) < 0){
        printf("Failed to open output file! /n");
        return;
    }
    
    AVStream* video_st;
    // 通过媒体文件控制者获取输出文件的流媒体数据，这里 AVCodec * 写 0 ， 默认会为我们计算出合适的编码格式
    video_st = avformat_new_stream(pFormatCtx, 0);
    
    // 设置 25 帧每秒 ，也就是 fps 为 25
    video_st->time_base.num = 1;
    video_st->time_base.den = 25;
    
    if (video_st==NULL){
        return ;
    }
    
    // 用户存储编码所需的参数格式等等
    AVCodecContext* pCodecCtx;
    
    // 从媒体流中获取到编码结构体，他们是一一对应的关系，一个 AVStream 对应一个  AVCodecContext
    //    pCodecCtx = video_st->codec;
    
    AVCodec *avcodec = avcodec_find_encoder(video_st->codecpar->codec_id);
    pCodecCtx = avcodec_alloc_context3(avcodec);
    // 设置编码器的 id，每一个编码器都对应着自己的 id，例如 h264 的编码 id 就是 AV_CODEC_ID_H264
    pCodecCtx->codec_id = AV_CODEC_ID_H264;
    
    // 设置编码类型为 视频编码
    pCodecCtx->codec_type = AVMEDIA_TYPE_VIDEO;
    
    // 设置像素格式为 yuv 格式
    pCodecCtx->pix_fmt = AV_PIX_FMT_YUV420P;
    
    // 设置视频的宽高
    pCodecCtx->width = 1280;
    pCodecCtx->height = 720;
    
    // 设置比特率，每秒传输多少比特数 bit，比特率越高，传送速度越快，也可以称作码率，
    // 视频中的比特是指由模拟信号转换为数字信号后，单位时间内的二进制数据量。
    pCodecCtx->bit_rate = 2000000;
    
    // 设置图像组层的大小。
    // 图像组层是在 MPEG 编码器中存在的概念，图像组包 若干幅图像, 组头包 起始码、GOP 标志等,如视频磁带记录器时间、控制码、B 帧处理码等;
    pCodecCtx->gop_size=250;
    
    // 设置 25 帧每秒 ，也就是 fps 为 25
    pCodecCtx->time_base.num = 1;
    pCodecCtx->time_base.den = 25;
    
    //设置 H264 中相关的参数
    //pCodecCtx->me_range = 16;
    //pCodecCtx->max_qdiff = 4;
    //pCodecCtx->qcompress = 0.6;
    pCodecCtx->qmin = 10;
    pCodecCtx->qmax = 51;
    
    // 设置 B 帧最大的数量，B帧为视频图片空间的前后预测帧， B 帧相对于 I、P 帧来说，压缩率比较大，也就是说相同码率的情况下，
    // 越多 B 帧的视频，越清晰，现在很多打视频网站的高清视频，就是采用多编码 B 帧去提高清晰度，
    // 但同时对于编解码的复杂度比较高，比较消耗性能与时间
    pCodecCtx->max_b_frames=3;
    
    // 可选设置
    AVDictionary *param = 0;
    //H.264
    if(pCodecCtx->codec_id == AV_CODEC_ID_H264) {
        // 通过--preset的参数调节编码速度和质量的平衡。
        av_dict_set(&param, "preset", "slow", 0);
        
        // 通过--tune的参数值指定片子的类型，是和视觉优化的参数，或有特别的情况。
        // zerolatency: 零延迟，用在需要非常低的延迟的情况下，比如电视电话会议的编码
        //        av_dict_set(&param, "tune", "zerolatency", 0);
        
    }
    av_dump_format(pFormatCtx, 0, out_file, 1);
    // 通过 codec_id 找到对应的编码器
    AVCodec *pCodec = avcodec_find_encoder(pCodecCtx->codec_id);
    if (!pCodec){
        printf("Can not find encoder! /n");
        return;
    }
    
    // 打开编码器，并设置参数 param
    if (avcodec_open2(pCodecCtx, pCodec,&param) < 0){
        printf("Failed to open encoder! /n");
        return;
    }
    AVFrame *pFrame = av_frame_alloc();
    
    // 通过像素格式(这里为 YUV)获取图片的真实大小，例如将 480 * 720 转换成 int 类型
    //    int picture_size = avpicture_get_size(pCodecCtx->pix_fmt, pCodecCtx->width, pCodecCtx->height);
    int picture_size = pCodecCtx->width * pCodecCtx->height * 3 / 2;
    
    
    // 将 picture_size 转换成字节数据，byte
    unsigned char *picture_buf = (uint8_t *)av_malloc(picture_size);
    
    // 设置原始数据 AVFrame 的每一个frame 的图片大小，AVFrame 这里存储着 YUV 非压缩数据
    int dst[3] = {1280 * 720 ,1280 * 720 / 4,1280 * 720 / 4};
    //    avpicture_fill((AVPicture *)pFrame, picture_buf, pCodecCtx->pix_fmt, pCodecCtx->width, pCodecCtx->height);
    int ff = av_image_fill_arrays(pFrame->data, dst, picture_buf, AV_PIX_FMT_YUV420P, 1280, 720, 64);
    if (ff <= 0) {
        printf("fill arrays failed!");
        return;
    }
    
    // 编写 h264 封装格式的文件头部，基本上每种编码都有着自己的格式的头部，想看具体实现的同学可以看看 h264 的具体实现
    int ret = avformat_write_header(pFormatCtx,NULL);
    if (ret < 0) {
        printf("write header is failed");
        return;
    }
    
    AVPacket pkt;
    
    //    AVCodec* pCodec;
    av_new_packet(&pkt,picture_size);
    
    // 设置 yuv 数据中 y 图的宽高
    int y_size = pCodecCtx->width * pCodecCtx->height;
    int framenum = 200;
    int framecnt = 0;
    for (int i=0; i<framenum; i++){
        //Read raw YUV data
        if (fread(picture_buf, 1, y_size * 3 / 2, in_file) <= 0){
            printf("Failed to read raw data! /n");
            return ;
        }else if(feof(in_file)){
            break;
        }
        
        //        pFrame->data[0] = picture_buf;              // Y
        //        pFrame->data[1] = picture_buf+ y_size;      // U
        //        pFrame->data[2] = picture_buf+ y_size*5/4;  // V
        
        memcpy(pFrame->data[0], picture_buf, y_size);
        memcpy(pFrame->data[1], picture_buf + y_size, y_size / 4);
        memcpy(pFrame->data[2], picture_buf + y_size * 5 / 4, y_size / 4);
        
        pFrame->format = AV_PIX_FMT_YUV420P;
        pFrame->height = 720;
        pFrame->width = 1280;
        pFrame->linesize[0] =  1280;
        pFrame->linesize[1] = 1280 / 2;
        pFrame->linesize[2] = 1280 / 2;
        //PTS
        //pFrame->pts=i;
        // 设置这一帧的显示时间
        pFrame->pts=i * (video_st->time_base.den) / ((video_st->time_base.num)*25);
        int got_picture=0;
        // 利用编码器进行编码，将  pFrame 编码后的数据传入  pkt 中
        //        int ret = avcodec_encode_video2(pCodecCtx, &pkt,pFrame, &got_picture);
        int ret = avcodec_send_frame(pCodecCtx, pFrame);
        if (ret != 0) {
            NSLog(@"send frame failed;");
            return;
        }
        
        ret = avcodec_receive_packet(pCodecCtx, &pkt);
        //        avcodec_send_frame()/avcodec_receive_packet()
        if(ret != 0){
            printf("Failed to encode receive packet! \n");
            /*
             AVERROR(EAGAIN):在这种情况下输出是不可用的-用户必须尝试发送一个输入。
             AVERROR_EOF:解码器已经flushed，这里不会有任何packet输出
             AVERROR(EINVAL):编解码器没有被打开，或者他是一个编码器
             */
            switch (ret) {
                case AVERROR(EAGAIN):
                    NSLog(@"eagain");
                    break;
                case AVERROR_EOF:
                    NSLog(@"eof");
                    break;
                case AVERROR(EINVAL):
                    NSLog(@"einval");
                    return;
                default:
                    break;
            }
            
        }else {
            printf("Success to encode receive packet! \n");
            got_picture = 1;
        }
        
        // 编码成功后写入 AVPacket 到 输入输出数据操作着 pFormatCtx 中，当然，记得释放内存
        if (got_picture==1){
            printf("Succeed to encode frame: %5d/tsize:%5d \n",framecnt,pkt.size);
            framecnt++;
            pkt.stream_index = video_st->index;
            ret = av_write_frame(pFormatCtx, &pkt);
            av_free_packet(&pkt);
        }
    }
    
    
    
    
    int ret2 = flush_encoder(pFormatCtx,0);
    if (ret2 < 0) {
        printf("Flushing encoder failed/n");
        return;
    }
    
    // 写入数据流尾部到输出文件当中，并释放文件的私有数据
    av_write_trailer(pFormatCtx);
    
    if (video_st){
        // 关闭编码器
        avcodec_close(video_st->codec);
        // 释放 AVFrame
        av_free(pFrame);
        // 释放图片 buf，就是 free() 函数，硬要改名字，当然这是跟适应编译环境有关系的
        av_free(picture_buf);
    }
    
    // 关闭输入数据的缓存
    avio_close(pFormatCtx->pb);
    // 释放 AVFromatContext 结构体
    avformat_free_context(pFormatCtx);
    
    // 关闭输入文件
    fclose(in_file);
}
