#ifndef _RECORD_FORMAT_H_
#define _RECORD_FORMAT_H_

#ifdef __cplusplus
extern "C" {
#endif
    
#import "rjone.h"

typedef struct _RECORD_FORAMT_STREAM_INFO_
{	
	int codec_id;
	int audio_sample_fmt;	
	int audio_sample_rate;
	int audio_channel_layout;
	int audio_channels;
	int video_framerate;
	int video_width;
	int video_height;
}RECORD_FORAMT_STREAM_INFO;


typedef struct _RECORD_FILE_INFO_
{
	RECORD_FORAMT_STREAM_INFO stVideo;  //视频参数
	RECORD_FORAMT_STREAM_INFO stAudio; //音频参数
	int iHaveVideoData;    //为 iHaveVideoData = 1 时，表示有视频数据
	int iHaveAudioData;   //为 iHaveAudioData = 1 时，表示有音频数据
	int iFileRecSecs;        //文件录制的时间长度，单位是秒
}RECORD_FILE_INFO;


int RF_InitFormatLib();
int RF_DestroyFormatLib();

HANDLE RF_CreateRecordFile(char * pFileName,RECORD_FORAMT_STREAM_INFO * pVideoStream,RECORD_FORAMT_STREAM_INFO * pAudioStream);
int RF_WriteVideoFrame(HANDLE  hHandle,char * pData,int iLen);
int RF_WriteAudioFrame(HANDLE  hHandle,char * pData,int iLen);
int  RF_CloseRecordFile(HANDLE  hHandle);

int RF_ReSetRecordFileVideoInfo(HANDLE  hHandle,int fps,int width,int height,int codec);



void *RF_OpenReadFile(const char *ofile);
int  RF_GetFileInfo(void *FileHandle,RECORD_FILE_INFO * pstFileInfo);
int  RF_ReadFrame(void *FileHandle,char ** pDataAddr,int * iStreamIndex,int * isKeyFrame,int iReadSpeed, struct timeval * pPlayTime);
int  RF_GetFileAllTime(void *FileHandle);
int RF_JumpReadFile(void *FileHandle,int time,int iDdirection);
int RF_StopReadFile(void *FileHandle);
int RF_PauseReadFile(void *FileHandle);
int RF_ResumeReadFile(void *FileHandle);


#ifdef __cplusplus
}
#endif

#endif 
