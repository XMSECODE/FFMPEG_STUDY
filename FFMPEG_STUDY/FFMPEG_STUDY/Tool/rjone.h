

#ifndef _RJONE_H_
#define _RJONE_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "rjone_type.h"


#define RJONE_SYS_VER  (0x01000003)

#define RJONE_SUCCESS   (1)
#define RJONE_FAILED      (-1)

#define RJONE_FRAME_SEND_PACKET_LEN (10*1024)


#define RJONE_LISTEN_PORT (11666)



typedef enum {
	IOCTRL_TYPE_UNKN,
	//�ֳ���Ƶ��Ƶ����
	IOCTRL_TYPE_LIVE_START_REQ,
	IOCTRL_TYPE_LIVE_START_RESP,

	IOCTRL_TYPE_LIVE_STOP_REQ,
	IOCTRL_TYPE_LIVE_STOP_RESP,
	

	//��Ƶ�Խ�
	IOCTRL_TYPE_LIVE_AUDIO_SPEAK_START_REQ,
	IOCTRL_TYPE_LIVE_AUDIO_SPEAK_START_RESP,

	IOCTRL_TYPE_LIVE_AUDIO_SPEAK_STOP_REQ,
	IOCTRL_TYPE_LIVE_AUDIO_SPEAK_STOP_RESP,


	//���߲���
	IOCTRL_TYPE_GET_AP_PARAMETERS_REQ,
	IOCTRL_TYPE_GET_AP_PARAMETERS_RESP,

	IOCTRL_TYPE_SET_AP_PARAMETERS_REQ,
	IOCTRL_TYPE_SET_AP_PARAMETERS_RESP,

	IOCTRL_TYPE_GET_STA_PARAMETERS_REQ,
	IOCTRL_TYPE_GET_STA_PARAMETERS_RESP,

	IOCTRL_TYPE_SET_STA_PARAMETERS_REQ,
	IOCTRL_TYPE_SET_STA_PARAMETERS_RESP,

	IOCTRL_TYPE_LIST_WIFI_AP_REQ,
	IOCTRL_TYPE_LIST_WIFI_AP_RESP,


	//��̨����
	IOCTRL_TYPE_PTZ_COMMAND_REQ,
	IOCTRL_TYPE_PTZ_COMMAND_RESP,


	//¼���ļ��ط����ز���
	IOCTRL_TYPE_LIST_RECORDFILES_REQ,
	IOCTRL_TYPE_LIST_RECORDFILES_RESP,

	IOCTRL_TYPE_DOWNLOAD_RECORD_FILE_REQ,
	IOCTRL_TYPE_DOWNLOAD_RECORD_FILE_RESP,

	IOCTRL_TYPE_RECORD_PLAYCONTROL_REQ,
	IOCTRL_TYPE_RECORD_PLAYCONTROL_RESP,
	
	//��������豸¼��
	IOCTRL_TYPE_NET_TRIGGER_RECORD_START_REQ,
	IOCTRL_TYPE_NET_TRIGGER_RECORD_START_RESP,

	IOCTRL_TYPE_NET_TRIGGER_RECORD_CHECK_REQ,
	IOCTRL_TYPE_NET_TRIGGER_RECORD_CHECK_RESP,

	IOCTRL_TYPE_NET_TRIGGER_RECORD_STOP_REQ,
	IOCTRL_TYPE_NET_TRIGGER_RECORD_STOP_RESP,

	//�豸����
	IOCTRL_TYPE_PUSH_EVENT_REQ,
	IOCTRL_TYPE_PUSH_EVENT_RESP,

	IOCTRL_TYPE_GET_PUSH_PARAMETERS_REQ,
	IOCTRL_TYPE_GET_PUSH_PARAMETERS_RESP,
	
	IOCTRL_TYPE_SET_PUSH_PARAMETERS_REQ,
	IOCTRL_TYPE_SET_PUSH_PARAMETERS_RESP,


	//�豸��������
	IOCTRL_TYPE_GET_SYSFWVER_REQ,	//App to Device
	IOCTRL_TYPE_GET_SYSFWVER_RESP,	//Device to App

	IOCTRL_TYPE_GET_DEV_TIME_REQ,
	IOCTRL_TYPE_GET_DEV_TIME_RESP,
	
	IOCTRL_TYPE_SET_DEV_TIME_REQ,
	IOCTRL_TYPE_SET_DEV_TIME_RESP,

	IOCTRL_TYPE_CHANGE_DEV_PASSWORD_REQ,
	IOCTRL_TYPE_CHANGE_DEV_PASSWORD_RESP,

	IOCTRL_TYPE_GET_DEV_INTERNET_FLAG_REQ,  
 	IOCTRL_TYPE_GET_DEV_INTERNET_FLAG_RESP, 
 	
 	IOCTRL_TYPE_SET_DEV_INTERNET_FLAG_REQ,  
 	IOCTRL_TYPE_SET_DEV_INTERNET_FLAG_RESP,


	// ͼ���������
	IOCTRL_TYPE_GET_DEV_IMAGE_PARAMETERS_REQ,
	IOCTRL_TYPE_GET_DEV_IMAGE_PARAMETERS_RESP,
	
	IOCTRL_TYPE_SET_DEV_IMAGE_PARAMETERS_REQ,
	IOCTRL_TYPE_SET_DEV_IMAGE_PARAMETERS_RESP,


	// ��Ƶ��������
	IOCTRL_TYPE_GET_DEV_VIDEO_PARAMETERS_REQ,
	IOCTRL_TYPE_GET_DEV_VIDEO_PARAMETERS_RESP,
	
	IOCTRL_TYPE_SET_DEV_VIDEO_PARAMETERS_REQ,
	IOCTRL_TYPE_SET_DEV_VIDEO_PARAMETERS_RESP,


	//��������
	IOCTRL_TYPE_GET_DEVICE_ALARM_REQ,
	IOCTRL_TYPE_GET_DEVICE_ALARM_RESP,
	IOCTRL_TYPE_SET_DEVICE_ALARM_REQ,
	IOCTRL_TYPE_SET_DEVICE_ALARM_RESP,


	//¼���������
	IOCTRL_TYPE_GET_RECORD_PARAMETERS_REQ,
	IOCTRL_TYPE_GET_RECORD_PARAMETERS_RESP,
	
	IOCTRL_TYPE_SET_RECORD_PARAMETERS_REQ,
	IOCTRL_TYPE_SET_RECORD_PARAMETERS_RESP,	
	

	//��֤���� &  ��Ȩ
	IOCTRL_TYPE_AUTHORIZE_REQ, 
	IOCTRL_TYPE_AUTHORIZE_RESP,
	
	//�豸����	
	IOCTRL_TYPE_UPGRADE_REQ,		       //App to Device, data: upgrade file size, 
	IOCTRL_TYPE_UPGRADE_READY,		//Device to App, Device is ready for receiving upgrade firmware. App begin to send data
	IOCTRL_TYPE_UPGRADE_QUERY,		//App to Device, Query device to upgrade firmware ok ? after sending upgrade data over
	IOCTRL_TYPE_UPGRADE_OK,			//Device to App
	IOCTRL_TYPE_UPGRADE_FAILED,		//Device to App


	//��������
	IOCTRL_TYPE_DOORBELL_OPEN_REQ,             
	IOCTRL_TYPE_DOORBELL_OPEN_RESP,      


	// SD�� TF�� ����
	IOCTRL_TYPE_SET_DEVICE_SDFORMAT_REQ,
	IOCTRL_TYPE_SET_DEVICE_SDFORMAT_RESP,
	
	IOCTRL_TYPE_SDFORMAT_QUERY_REQ,
	IOCTRL_TYPE_SDFORMAT_QUERY_RESP,
		
	IOCTRL_TYPE_GET_SD_INFO_REQ,
	IOCTRL_TYPE_GET_SD_INFO_RESP,   
	
	//������RTSP ����
	IOCTRL_TYPE_GET_RTSP_INFO_REQ,
	IOCTRL_TYPE_GET_RTSP_INFO_RESP,


	//SUMMER ���� a115
	//������̨& �¶� peripheral equipment���ʱ� 
	IOCTRL_TYPE_GET_PERIPHERAL_EQUIPMENT_INFO_REQ,
	IOCTRL_TYPE_GET_PERIPHERAL_EQUIPMENT_INFO_RESP,	

	//�����豸����Ƶ�� 50hz  or 60hz
	IOCTRL_TYPE_GET_FREQUENCY_INFO_REQ,
	IOCTRL_TYPE_GET_FREQUENCY_INFO_RESP,

	IOCTRL_TYPE_SET_FREQUENCY_INFO_REQ,
	IOCTRL_TYPE_SET_FREQUENCY_INFO_RESP,

	/********************************  �г���¼�ǲ���***************************/
	//�ļ���ѯ
	IOCTRL_TYPE_DC_GET_FILE_LIST_REQ = 200,
	IOCTRL_TYPE_DC_GET_FILE_LIST_RESP,

	//���´洢��Ϣ��ѯ
	IOCTRL_TYPE_DC_CHECK_SAVE_INFO_BY_MONTH_REQ,   //��ѯһ��������Щ���д洢����
	IOCTRL_TYPE_DC_CHECK_SAVE_INFO_BY_MONTH_RESP,

	//ɾ���ļ�
	IOCTRL_TYPE_DC_DELETE_FILE_REQ,
	IOCTRL_TYPE_DC_DELETE_FILE_RESP,

	//�����ļ�
	IOCTRL_TYPE_DC_DOWNLOAD_FILE_REQ,
	IOCTRL_TYPE_DC_DOWNLOAD_FILE_RESP,


	//���߻ط�
	IOCTRL_TYPE_DC_ONLINE_PLAY_FILE_REQ,
	IOCTRL_TYPE_DC_ONLINE_PLAY_FILE_RESP,
	
	//IOCTRL_TYPE_DC_ONLINE_PLAY_CTRL_REQ,   
	//IOCTRL_TYPE_DC_ONLINE_PLAY_CTRL_RESP,

	//ʵʱ����
	IOCTRL_TYPE_DC_SNAP_REQ,
	IOCTRL_TYPE_DC_SNAP_RESP,


	//���ӹ�
	IOCTRL_TYPE_DC_ELECTRONIC_DOG_GET_REQ,
	IOCTRL_TYPE_DC_ELECTRONIC_DOG_GET_RESP,
	
	IOCTRL_TYPE_DC_ELECTRONIC_DOG_SET_REQ,
	IOCTRL_TYPE_DC_ELECTRONIC_DOG_SET_RESP,


	//���ô����ٶ�
	IOCTRL_TYPE_DC_SET_UART_REQ,
	IOCTRL_TYPE_DC_SET_UART_RESP,

	//���󴮿ڿ���
	IOCTRL_TYPE_DC_REQUEST_UART_CTRL_REQ,
	IOCTRL_TYPE_DC_REQUEST_UART_CTRL_RESP,

	//�������ݷ���   �豸-> app
	IOCTRL_TYPE_DC_SEND_UART_DATA_REQ,
	IOCTRL_TYPE_DC_SEND_UART_DATA_RESP,

	//�������ݽ���   app -> �豸
	IOCTRL_TYPE_DC_WRITE_UART_DATA_REQ,
	IOCTRL_TYPE_DC_WRITE_UART_DATA_RESP,


	//ֹͣ�����ļ�
	IOCTRL_TYPE_DC_STOP_DOWNLOAD_FILE_REQ,
	IOCTRL_TYPE_DC_STOP_DOWNLOAD_FILE_RESP,


	//��ȡ�汾�Žӿ�2
	IOCTRL_TYPE_GET_DEVAPPVER_REQ,	
	IOCTRL_TYPE_GET_DEVAPPVER_RESP,	


	//ʱ�����ýӿ�2
	IOCTRL_TYPE_GET_DEV_TIME2_REQ,
	IOCTRL_TYPE_GET_DEV_TIME2_RESP,
	
	IOCTRL_TYPE_SET_DEV_TIME2_REQ,
	IOCTRL_TYPE_SET_DEV_TIME2_RESP,

	//�ϴ�ץ��ͼƬ����Ƶ�ļ�����Ϣ mac -> app
	IOCTRL_TYPE_SEND_SNAP_FILE_INFO_REQ,
	IOCTRL_TYPE_SEND_SNAP_FILE_INFO_RESP,

	//������ʱ��������
	IOCTRL_TYPE_DC_CREATE_TMP_CONNECT_PASSWORD_REQ,
	IOCTRL_TYPE_DC_CREATE_TMP_CONNECT_PASSWORD_RESP,


	//�ϴ�ɾ���ļ�����Ϣ mac -> app
	IOCTRL_TYPE_SEND_DEL_FILE_INFO_REQ,
	IOCTRL_TYPE_SEND_DEL_FILE_INFO_RESP,

	//��ȡtf ���Ͼ����ļ���Ϣ
	IOCTRL_TYPE_DC_GET_TFCARD_INFO_REQ,
	IOCTRL_TYPE_DC_GET_TFCARD_INFO_RESP,

	//�����豸��APP ����ʵʱGPS+OBD������
	IOCTRL_TYPE_GET_GPS_OBD_SEND_PARAMETERS_REQ,
	IOCTRL_TYPE_GET_GPS_OBD_SEND_PARAMETERS_RESP,
	
	IOCTRL_TYPE_SET_GPS_OBD_SEND_PARAMETERS_REQ,
	IOCTRL_TYPE_SET_GPS_OBD_SEND_PARAMETERS_RESP,

	
	//�ϴ�GPS OBD ʵʱ���� mac -> app
	IOCTRL_TYPE_SEND_GPS_OBD_REQ,
	IOCTRL_TYPE_SEND_GPS_OBD_RESP,

	//�õ�����������ݵİ汾��
	IOCTRL_TYPE_GET_DEV_ALL_APPVER_REQ,	
	IOCTRL_TYPE_GET_DEV_ALL_APPVER_RESP,


	//֪ͨAPP  �Ƿ����˾��� ��չ�Ṧ��(�豸�������͸�APP��APP����ҪӦ��)
	IOCTRL_TYPE_SEND_PIR_INFO_REQ,	
	IOCTRL_TYPE_SEND_PIR_INFO_RESP,
	
	/*********************************************************************************/
	
	
}RJONE_IOCTRL_TYPE;



/******************************************************************************************
								��Ƶ��Ƶ����
*******************************************************************************************/


///////////������ݽṹ////////

typedef enum
{
	FRAME_TYPE_BASE = 0,
    	FRAME_TYPE_VIDEO,			//��Ƶ����֡
    	FRAME_TYPE_AUDIO,			//��Ƶ����֡
}RJONE_FRAME_TYPE;


typedef enum 
{
	VIDEO_FRAME_FLAG_I	= 0x00,	// Video I Frame
	VIDEO_FRAME_FLAG_P	= 0x01,	// Video P Frame
	VIDEO_FRAME_FLAG_B	= 0x02,	// Video B Frame
}RJONE_VIDEO_FRAME;

typedef enum
{
	ASAMPLE_RATE_8K	= 0x00,
	ASAMPLE_RATE_11K= 0x01,
	ASAMPLE_RATE_12K= 0x02,
	ASAMPLE_RATE_16K= 0x03,
	ASAMPLE_RATE_22K= 0x04,
	ASAMPLE_RATE_24K= 0x05,
	ASAMPLE_RATE_32K= 0x06,
	ASAMPLE_RATE_44K= 0x07,
	ASAMPLE_RATE_48K= 0x08,
}RJONE_AUDIO_SAMPLERATE;


typedef enum
{
	ADATABITS_8	= 0,
	ADATABITS_16	= 1,
}RJONE_AUDIO_DATABITS;

typedef enum
{
	ACHANNEL_MONO	= 0,
	ACHANNEL_STEREO	= 1,
}RJONE_AUDIO_CHANNEL;

typedef enum
{
	CODECID_UNKN = 1,
	CODECID_V_MJPEG,
	CODECID_V_MPEG4,
	CODECID_V_H264,
	
	CODECID_A_PCM ,
	CODECID_A_ADPCM,
	CODECID_A_SPEEX,	
	CODECID_A_AMR,
	CODECID_A_AAC,
	CODECID_A_G711A,
	CODECID_A_G726,         
	CODECID_A_AC3,
	CODECID_A_MP3,
	CODECID_V_H265,
}RJONE_CODE_TYPE;

typedef enum
{
	USE_TYPE_UNKN,
	USE_TYPE_LIVE,
	USE_TYPE_PLAYBACK,
	USE_TYPE_SPEAK,
}RJONE_FRAME_USE_TYPE;





////////����Ӧ�����ݽṹ////////


//IOCTRL_TYPE_LIVE_START_REQ,
//IOCTRL_TYPE_LIVE_START_RESP,
typedef struct _LIVE_START_REQ_
{
	UINT8 u8EnableVideoSend;  // 1: ������Ƶ��0 : ��������Ƶ 
	UINT8 u8EnableAudioSend;  // 1. ������Ƶ.    0 : ��������Ƶ
	UINT8 u8VideoChan;		//������Ƶͨ�����ݣ� 0 Ϊ������720p��1 Ϊ������VGA��2 ΪQVGA
	UINT8 u8Reserved[9];
}RJONE_LIVE_START_REQ;


typedef struct _LIVE_START_RESP_
{
	INT32 s32Result;		// RJONE_SUCCESS: �ɹ�  . ���ɹ��򷵻ش���ֵ	
	UINT8 u8Reserved[8];
}RJONE_LIVE_START_RESP;



//IOCTRL_TYPE_LIVE_STOP_REQ,
//IOCTRL_TYPE_LIVE_STOP_RESP,
typedef struct _LIVE_STOP_REQ_
{	
	UINT8 u8Reserved[8];
}RJONE_LIVE_STOP_REQ;


typedef struct _LIVE_STOP_RESP_
{
	INT32 s32Result;		// RJONE_SUCCESS: �ɹ�  . ���ɹ��򷵻ش���ֵ	
	UINT8 u8Reserved[8];
}RJONE_LIVE_STOP_RESP;



//IOCTRL_TYPE_LIVE_AUDIO_SPEAK_START_REQ,
//IOCTRL_TYPE_LIVE_AUDIO_SPEAK_START_RESP,
typedef struct _AUDIO_SPEAK_START_REQ
{
	UINT8 u8Reserved[8];
}RJONE_AUDIO_SPEAK_START_REQ;

typedef struct _AUDIO_SPEAK_START_RESP
{
	INT32 s32Result;					// s32Result = RJONE_SUCCESS:      ��Ȩ�ɹ�����ʼ�Խ�
									// s32Result != RJONE_SUCCESS: ��Ȩʧ�ܣ����ش���ԭ��
	UINT8 u8Reserved[8];
}RJONE_AUDIO_SPEAK_START_RESP;



//IOCTRL_TYPE_LIVE_AUDIO_SPEAK_STOP_REQ,
//IOCTRL_TYPE_LIVE_AUDIO_SPEAK_STOP_RESP,
typedef struct _AUDIO_SPEAK_STOP_REQ
{
	UINT8 u8Reserved[8];
}RJONE_AUDIO_SPEAK_STOP_REQ;

typedef struct _AUDIO_SPEAK_STOP_RESP
{
	INT32 s32Result;	
	UINT8 u8Reserved[8];
}RJONE_AUDIO_SPEAK_STOP_RESP;

///////////////////////////////////////////////////////////////////////////////////////////



/******************************************************************************************
								���߲���
*******************************************************************************************/

////////������ݽṹ////////
typedef enum
{
	IOCTRL_WIFIAPENC_INVALID		= 0x00, 
	IOCTRL_WIFIAPENC_NONE			= 0x01,
	IOCTRL_WIFIAPENC_WEP_NO_PWD		= 0x02,
	IOCTRL_WIFIAPENC_WEP_WITH_PWD	= 0x03,
	IOCTRL_WIFIAPENC_WPA_TKIP		= 0x04, 
	IOCTRL_WIFIAPENC_WPA_AES		= 0x05, 
	IOCTRL_WIFIAPENC_WPA2_TKIP		= 0x06, 
	IOCTRL_WIFIAPENC_WPA2_AES		= 0x07,
	IOCTRL_WIFIAPENC_WPA_PSK_AES    = 0x08,
	IOCTRL_WIFIAPENC_WPA_PSK_TKIP   = 0x09,	
	IOCTRL_WIFIAPENC_WPA2_PSK_AES   = 0x0A,
	IOCTRL_WIFIAPENC_WPA2_PSK_TKIP  = 0x0B,
}RJONE_WIFIAP_ENC;


#define MAX_NTP_LIST_ITEM_NUM (10)

typedef struct _NTP_INFO_ST_
{
	char ntp_server_url[256];    //ntp ��������ַ�� clock.via.net������Ĭ����ַΪclock.via.net
	int ntp_server_port;	    // ntp �������˿�Ĭ��Ϊ123
}NTP_INFO_ST;


typedef struct _NTP_ADDR_LIST_
{	
	NTP_INFO_ST ntp[MAX_NTP_LIST_ITEM_NUM];   //����ͬʱ���ö���NTP ������Ϣ
	int ntp_available_num;  // ntp_available_num��ʾ�м�����Ч��NTP��Ϣ�� ntp_available_num ����С�ڵ���MAX_NTP_LIST_ITEM_NUM
}NTP_ADDR_LIST;



typedef struct _RJONE_LIST_AP_INFO_
{
	CHAR  strAddress[20];		      // ������ip��ַ
	CHAR  strSsid[64];			      // SSID
	UINT16 u16Channel;			// �ŵ�
	UINT8   u8Enctype;			// ����ģʽ  �ο�RJONE_WIFIAP_ENC
	UINT8   u8SignalLevel;		// �ź�ǿ�ȣ�ֵ�ķ�Χ[0-100]��ֵԽ���ź�Խǿ��
	UINT8   u8Reserve[8]; 		//����
}RJONE_LIST_AP_INFO;

typedef struct
{
	CHAR strSsid[64];				//WiFi ssid 
	CHAR strPassword[64];		//WiFi ����
	UINT8 u8Enctype;			       // ����ģʽ �ο� RJONE_WIFIAP_ENC
    	UINT8 u8SignalChannel;		//wifi  �ŵ� [1,14]
    	UINT8 reserved[10];
 }RJONE_STA_INFO,RJONE_AP_INFO;


////////����Ӧ�����ݽṹ////////

//IOCTRL_TYPE_GET_AP_PARAMETERS_REQ,
//IOCTRL_TYPE_GET_AP_PARAMETERS_RESP,
typedef struct _GET_AP_PARAMETERS_REQ
{
	UINT8 u8Reserved[8];
}RJONE_GET_AP_PARAMETERS_REQ;


typedef struct _GET_AP_PARAMETERS_RESP
{
	INT32 s32Result;					//s32Result = RJONE_SUCCESS: ��ò����ɹ���
									//s32Result != RJONE_SUCCESS: ��ȡʧ��,���ش���ԭ��	
	RJONE_AP_INFO stApInfo;	
	UINT8 u8Reserved[8];
}RJONE_GET_AP_PARAMETERS_RESP;



//IOCTRL_TYPE_SET_AP_PARAMETERS_REQ,
//IOCTRL_TYPE_SET_AP_PARAMETERS_RESP,
typedef struct _SET_AP_PARAMETERS_REQ
{
	RJONE_AP_INFO stApInfo;
	UINT8 u8Reserved[8];
}RJONE_SET_AP_PARAMETERS_REQ;


typedef struct _SET_AP_PARAMETERS_RESP
{
	INT32 s32Result;	
	UINT8 u8Reserved[8];
}RJONE_SET_AP_PARAMETERS_RESP;




//IOCTRL_TYPE_GET_STA_PARAMETERS_REQ,
//IOCTRL_TYPE_GET_STA_PARAMETERS_RESP,
typedef struct _GET_STA_PARAMETERS_REQ
{
	UINT8 u8Reserved[8];
}RJONE_GET_STA_PARAMETERS_REQ;


typedef struct _GET_STA_PARAMETERS_RESP
{
	INT32 s32Result;					//s32Result = RJONE_SUCCESS: ��ò����ɹ���
										//s32Result != RJONE_SUCCESS: ��ȡʧ��,���ش���ԭ��
	RJONE_STA_INFO stStaInfo;	
	UINT8 u8Reserved[8];
}RJONE_GET_STA_PARAMETERS_RESP;



//IOCTRL_TYPE_SET_STA_PARAMETERS_REQ,
//IOCTRL_TYPE_SET_STA_PARAMETERS_RESP,
typedef struct _SET_STA_PARAMETERS_REQ
{
	RJONE_STA_INFO stStaInfo;
	UINT8 u8Reserved[8];
}RJONE_SET_STA_PARAMETERS_REQ;


typedef struct _SET_STA_PARAMETERS_RESP
{
	INT32 s32Result;			
	UINT8 u8Reserved[8];
}RJONE_SET_STA_PARAMETERS_RESP;




//IOCTRL_TYPE_LIST_WIFI_AP_REQ,
//IOCTRL_TYPE_LIST_WIFI_AP_RESP,
typedef struct _LIST_WIFI_AP_REQ
{
	UINT8 u8Reserved[8];
}RJONE_LIST_WIFI_AP_REQ;


typedef struct _LIST_WIFI_AP_RESP
{
	INT32 s32Result;															
	UINT32 u32ApCount;			//���ҵ��� AP ����
	UINT8 u8Reserved[8];
	RJONE_LIST_AP_INFO  stApInfo[0]; 	//AP INFO ���ݵ�ַ						
}RJONE_LIST_WIFI_AP_RESP;



///////////////////////////////////////////////////////////////////////////////////////////


/******************************************************************************************
								��̨����
*******************************************************************************************/


////////������ݽṹ////////

typedef enum 
{
	IOCTRL_PTZ_STOP,
	IOCTRL_PTZ_UP,
	IOCTRL_PTZ_DOWN,
	IOCTRL_PTZ_LEFT,
	IOCTRL_PTZ_RIGHT, 
	IOCTRL_PTZ_BACK,
	IOCTRL_PTZ_FORWARD, 	
	IOCTRL_LENS_ZOOM_IN, 
	IOCTRL_LENS_ZOOM_OUT,    
}RJONE_PTZ_CMD;

////////����Ӧ�����ݽṹ////////
//IOCTRL_TYPE_PTZ_COMMAND_REQ,
//IOCTRL_TYPE_PTZ_COMMAND_RESP,
typedef struct _PTZ_COMMAND_REQ
{
	RJONE_PTZ_CMD enPtzCmd;	//PTZ ��������
	UINT8 u8Speed;				// PTZ �����ٶȷ�Χ[1-10] ,ֵԽ���ٶ�Խ��
	UINT8 u8Reserved[7];
}RJONE_PTZ_COMMAND_REQ;


typedef struct _PTZ_COMMAND_RESP
{
	INT32 s32Result;		
	UINT8 u8Reserved[8];
}RJONE_PTZ_COMMAND_RESP;


///////////////////////////////////////////////////////////////////////////////////////////////////



/******************************************************************************************
								����¼���ļ�����
*******************************************************************************************/

////////������ݽṹ////////
typedef struct _DAY_TIME_
{
	UINT16 u16Year;
	UINT8  u8Month;	//January=0,...
	UINT8  u8Day;		
	UINT8  u8Hour;
	UINT8  u8Minute;
	UINT8  u8Second;
	UINT8 u8Reserved[1];
}RJONE_DAY_TIME;



typedef struct _RJONE_RECORD_FILE_
{
	CHAR strFileName[40];		              //�ļ�����
	UINT32 u32FileLen;			       //�ļ�����
}RJONE_RECORD_FILE;



// IOCTRL Record Playback Command
typedef enum 
{
	IOCTRL_RECORD_PLAY_CMD_START,	//command below is valid when IOCTRL_RECORD_PLAY_CMD_START is successful 
	IOCTRL_RECORD_PLAY_CMD_PAUSE,
	IOCTRL_RECORD_PLAY_CMD_RESUME,
	IOCTRL_RECORD_PLAY_CMD_STOP,
	IOCTRL_RECORD_PLAY_CMD_END,       //���������ָ���ļ����ŵ���β��ʱ���豸����ͻ��˷������
	IOCTRL_RECORD_PLAY_CMD_FAST,   // 1X, 2X, 4X
	IOCTRL_RECORD_PLAY_CMD_SEEKTIME,
}RJONE_RECORD_PLAY_CMD;



////////����Ӧ�����ݽṹ////////
//IOCTRL_TYPE_LIST_RECORDFILES_REQ,
//IOCTRL_TYPE_LIST_RECORDFILES_RESP,
typedef struct _LIST_RECORDFILES_REQ
{
	RJONE_DAY_TIME	  stStartTime; // ¼�������Ŀ�ʼʱ��
	RJONE_DAY_TIME	  stEndTime;   // ¼�������Ľ���ʱ��
	UINT8  u8Reserved[8];		
}RJONE_LIST_RECORDFILES_REQ;


typedef struct _LIST_RECORDFILES_RESP
{	
	INT32  s32Result;			//RJONE_SUCCESS: Success   RJONE_FAILED: search time don't belong to [stStartTime, stEndTime], within one day.
	UINT32   u32SearchFileTotal;			//���ϲ�ѯ�������ļ���������
	UINT8    u8Count;						// ��ǰ�����������ļ�����
	UINT8    u8EndFlg;					//  u8EndFlg = 1 ��ʾ��ǰ��Ϊ���һ�����Ͱ���
	UINT8    u8Index;						// �������к�	
	UINT8    u8Reserved[5];
	RJONE_RECORD_FILE	  stFile[0];		//�ļ���Ϣ�ĵ�ַ	
}RJONE_LIST_RECORDFILES_RESP;




//IOCTRL_TYPE_DOWNLOAD_RECORD_FILE_REQ,
//IOCTRL_TYPE_DOWNLOAD_RECORD_FILE_RESP,
typedef struct _DOWNLOAD_RECORD_FILE_REQ
{
	CHAR strFileName[40];		//�ļ�����	
	UINT8  u8Reserved[8];	
}RJONE_DOWNLOAD_RECORD_FILE_REQ;


typedef struct _DOWNLOAD_RECORD_FILE_RESP
{
	INT32  s32Result;			//RJONE_SUCCESS: �ɹ� :  ʧ�ܷ��ش���ԭ��
	UINT8  u8Reserved[8];	
}RJONE_DOWNLOAD_RECORD_FILE_RESP;


//IOCTRL_TYPE_RECORD_PLAYCONTROL_REQ,
//IOCTRL_TYPE_RECORD_PLAYCONTROL_RESP,
typedef struct _RECORD_PLAYCONTROL_REQ
{
	UINT16 u16Command;			//�ط�¼���������ο� RJONE_RECORD_PLAY_CMD
	UINT16 us16SeekTimeSec;	       // ���豸��ָ����ʱ��㣬���ط��ļ��� ��Χ [0 - �ļ�����ʱ���]
	UINT32 u32Param;			//��   u16Command = IOCTRL_RECORD_PLAY_CMD_FAST ʱ��
								//  u32Param = 1 : 1����  u32Param = 2 : 2����u32Param = 4 : 4����
	CHAR strFileName[40];		  //�ļ�����	
	UINT8  u8Reserved[8];
}RJONE_RECORD_PLAYCONTROL_REQ;


typedef struct _RECORD_PLAYCONTROL_RESP
{
	INT32    s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��
	UINT16  u16Command;		//�ط�¼���������ο� RJONE_RECORD_PLAY_CMD
	UINT16   s32FilePlaySec;		//���ز����ļ�������ʱ�䣬��λ���롣
	UINT8    u8Reserved[8];		
}RJONE_RECORD_PLAYCONTROL_RESP;



//IOCTRL_TYPE_NET_TRIGGER_RECORD_START_REQ,
//IOCTRL_TYPE_NET_TRIGGER_RECORD_START_RESP,
typedef struct _NET_TRIGGER_RECORD_START_REQ
{
	UINT8  u8Reserved[8];
}RJONE_NET_TRIGGER_RECORD_START_REQ;


typedef struct _NET_TRIGGER_RECORD_START_RESP
{
	INT32  	s32Result;			      //RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��
	UINT8    u8Reserved[8];		
}RJONE_NET_TRIGGER_RECORD_START_RESP;


//IOCTRL_TYPE_NET_TRIGGER_RECORD_CHECK_REQ,
//IOCTRL_TYPE_NET_TRIGGER_RECORD_CHECK_RESP,
typedef struct _NET_TRIGGER_RECORD_CHECK_REQ
{		
	UINT8  u8Reserved[8];
}RJONE_NET_TRIGGER_RECORD_CHECK_REQ;


typedef struct _NET_TRIGGER_RECORD_CHECK_RESP
{
	INT32 s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��
	UINT8    u8NowRecord;		// 0 û����¼�� 1 ��ʾ��¼��	
	UINT8  u8Reserved[7];
}RJONE_NET_TRIGGER_RECORD_CHECK_RESP;


//IOCTRL_TYPE_NET_TRIGGER_RECORD_STOP_REQ,
//IOCTRL_TYPE_NET_TRIGGER_RECORD_STOP_RESP,
typedef struct _NET_TRIGGER_RECORD_STOP_REQ
{		
	UINT8  u8Reserved[8];
}RJONE_NET_TRIGGER_RECORD_STOP_REQ;


typedef struct _NET_TRIGGER_RECORD_STOP_RESP
{
	INT32 s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��
	UINT8    u8Reserve[8];		
}RJONE_NET_TRIGGER_RECORD_STOP_RESP;




//////////////////////////////////////////////////////////////////////////////////////////////////


/******************************************************************************************
								�豸����˽��Э�鲿��
*******************************************************************************************/

////////������ݽṹ////////

#define RJONE_PUSH_NET_VERSION 0x1000
//��ϢID
typedef enum 
{
	PUSH_CMD_ID_DEV_REGISTER             = 1,  			//�豸ע����Ϣ,�豸->������
	PUSH_CMD_ID_DEV_REGISTER_REPLY       = 2,  			//�豸ע���Ӧ,������->�豸
	PUSH_CMD_ID_DEV_EVENT_NOTIFY         = 3,  			//�豸��Ϣ֪ͨ,�豸->������
	PUSH_CMD_ID_DEV_EVENT_NOTIFY_REPLY   = 4,  		//�豸��Ϣ֪ͨ��Ӧ,������->�豸
	PUSH_CMD_ID_PHONE_REGISTER           = 5,  			//�ֻ�ע����Ϣ,�ֻ�->������
	PUSH_CMD_ID_PHONE_REGISTER_REPLY     = 6,  		//�ֻ�ע���Ӧ,������->�ֻ�
	PUSH_CMD_ID_HEARTBEAT                = 7,  				//������Ϣ,�ֻ�<->������
	PUSH_CMD_ID_PUSH_EVENT_NOTIFY        = 9,  			//�ֻ��豸��Ϣ֪ͨ,������->�ֻ�
	PUSH_CMD_ID_PUSH_EVENT_NOTIFY_REPLY  = 10, 		//�ֻ��豸��Ϣ֪ͨ��Ӧ,�ֻ�->������
	PUSH_CMD_ID_PHONE_DEV_REGISTER       = 11, 		//�ֻ������豸ע��,�ֻ�->������
	PUSH_CMD_ID_PHONE_DEV_REGISTER_REPLY = 12, 	//�ֻ������豸ע���Ӧ,������->�ֻ�
	PUSH_CMD_ID_PHONE_DELETE_DEV         = 13, //�ֻ�ɾ�������豸,�ֻ�->������
}RJONE_PUSH_CMD_ID;


//�豸����
typedef enum 
{
	DEV_TYPE_DOOR_BELL = 1, //����
}RJONE_DEV_TYPE;


//�豸�¼�����
typedef enum 
{
	DEV_EVENT_DOOR_BELL_PUSHED = 1, //���屻����
	DEV_EVENT_DOOR_BELL_BROKEN = 2, //���屻ǿ��
}RJONE_DEV_EVENT_TYPE;


//========���������ֻ���ʹ��=========
typedef enum 
{
	LANGUAGE_ENGLISH = 1,
	LANGUAGE_CHINESE = 2,
}RJONE_PUSH_LANGUAGE_TYPE;


//������������
typedef enum
{
	EXTRA_DATA_NONE    = 0, //�޸�������
	EXTRA_DATA_SPEECH  = 1, //����
	EXTRA_DATA_PICTURE = 2, //ͼƬ
}RJONE_PUSH_EXTRA_DATA_TYPE;


//������Ϣ��ͷ
typedef struct PushNetPackHdr
{
	UINT16 u16Version; 			//��ǰ����Ϊ PUSH_NET_VERSION
	UINT16 u16Cmd;     			//��ϢID�������˰����ݸ�ʽ���� CommandId
	UINT32 u32PackLen; 			//�����ݳ���
} RJONE_PUSH_NET_PACK_HDRS;


//�豸ע����Ϣ,PUSH_CMD_ID_DEV_REGISTER
typedef struct PushCmdDevRegister
{
	CHAR strDevId[64];   				//�豸ΨһID
	INT8  s8DevType;     				//ȡֵ�� DevType
	INT8  s8Reserved[7];
}RJONE_PUSH_CMD_DEV_REGISTER;


//�豸ע���Ӧ,PUSH_CMD_ID_DEV_REGISTER_REPLY
typedef struct PushCmdDevRegisterReply
{
	INT8   s8Redirect;     				//�ض����־�������Ϊ0���豸��Ҫ���º���ķ�������ַ�Ͷ˿ڣ����������·�������ַע��
	INT8   s8Reserved[5];
	UINT16 u16ServerPort;   			//�������˿�
	CHAR   strServerIp[16]; 			//������IP
}RJONE_PUSH_DEV_REGISTER_REPLY;


//�豸��Ϣ֪ͨ,PUSH_CMD_ID_DEV_EVENT_NOTIFY
typedef struct PushCmdDevEventNotify
{
	CHAR strDevId[64];           	//�豸ΨһID
	INT8 s8DevType;         	//�豸����,ȡֵ�� DevType
	INT8 s8EventType;       	//�¼�����,ȡֵ�� DevEventType
	INT8 s8ExtraDataType;   	//������������,ȡֵ�� ExtraDataType
	INT8 s8Reserved[5];
	UINT32 u32Timestamp;     	//�¼���UTCʱ��
	UINT32 u32ExtraDataLen;  //�������ݳ���
	INT8   s8ExtraData[0]; 	//��������,������ extraDataLen �ֶξ���
} RJONE_PUSH_CMD_DEV_EVENT_NOTIFY;



//�ֻ�ע����Ϣ,PUSH_CMD_ID_PHONE_REGISTER
typedef struct PushCmdPhoneRegister
{
	CHAR   strPhoneId[64];     		//�ֻ�Ψһ��ʶ(����iOSΪϵͳ�����device token)
	INT8   s8PhoneType;       		//�ֻ����ͣ�ȡֵ�� PhoneType
	INT8   s8Language;        		//�ֻ����ԣ�ȡֵ�� LanguageType
	UINT16 u16EventExpireTime; 	//�豸�¼���������,���ֻ�δ���յ����豸�¼��ڷ���������������
	INT8    s8Timezone;        		//�ֻ�ʱ����ȡֵ[-24,24]
	INT8    s8AppId;          		//���ڱ�ʶ��ͬAPP��ID
	INT8   s8Reserved[2];
	UINT64 u64LastEventId;    	 	//���һ���ӷ������յ����¼�ID��û������0
}RJONE_PUSH_CMD_PHONE_REGISTER;


//�ֻ�ע���Ӧ,PUSH_CMD_ID_PHONE_REGISTER_REPLY
typedef struct PushCmdPhoneRegisterReply
{
	INT8   s8Redirect;     			//�ض����־�������Ϊ0���ֻ�APP��Ҫ���º���ķ�������ַ�Ͷ˿ڣ����������·�������ַע��
	INT8   s8Reserved[5];
	UINT16 u16ServerPort;   		//�������˿�
	CHAR   strServerIp[16]; 		//������IP
}RJONE_PUSH_CMD_PHONE_REGISTER_REPLY;


//�����ֻ������豸ע����Ϣ�е��豸�б���
typedef struct PhoneDevEntry
{
	CHAR strDevId[64]; 			//�豸ID
	CHAR strName[32];  			//���豸���ֻ��ϵ���ʾ����
} RJONE_PHONE_DEV_ENTRY;


//�ֻ������豸ע��,PUSH_CMD_ID_PHONE_DEV_REGISTER
typedef struct PushCmdPhoneDevRegister
{
	UINT32 u32DevCount; 						//�ֻ��������豸����
	UINT32 u32Reserved;
	RJONE_PHONE_DEV_ENTRY devEntries[0]; 		//�ֻ��������豸�б�������devCountָ��
}RJONE_PUSH_CMD_PHONE_DEV_REGISTER;


//�ֻ������豸ע���Ӧ,PUSH_CMD_ID_PHONE_DEV_REGISTER_REPLY
typedef struct PushCmdPhoneDevRegisterReply
{
	UINT32 u32DevCount; //�ɹ�ע����豸����
}RJONE_PUSH_CMD_PHONE_DEV_REGISTER_REPLY;


//�ֻ��豸��Ϣ֪ͨ,PUSH_CMD_ID_PUSH_EVENT_NOTIFY
 typedef struct PushCmdPushEventNotify
{
	CHAR   strDevId[64];       	//�豸ΨһID
	INT8   s8DevType;         	//�豸����,ȡֵ�� DevType
	INT8   s8EventType;       	//�¼�����,ȡֵ�� DevEventType
	INT8   s8Reserved;
	INT8   s8ExtraDataType;   //������������,ȡֵ�� ExtraDataType
	UINT32 u32Timestamp;     //�¼���UTCʱ��
	UINT64 u64EventId;     	//���������¼������ΨһID
	UINT32 u32ExtraDataLen;  //�������ݳ���
	INT8   s8ExtraData[0]; 	//��������,������ extraDataLen �ֶξ���
}RJONE_PUSH_CMD_PUSH_EVENT_NOTIFY;


//�ֻ��豸��Ϣ֪ͨ��Ӧ,PUSH_CMD_ID_PUSH_EVENT_NOTIFY_REPLY
typedef struct PushCmdPushEventNotifyReply
{
	UINT64 u64EventId;     //�յ����¼�ID
}RJONE_PUSH_CMD_PUSH_EVENT_NOTIFY_REPLY;

//�ֻ�ɾ�������豸,�ֻ�->������,PUSH_CMD_ID_PHONE_DELETE_DEV
typedef struct PushCmdPhoneDeleteDev
{
	char devId[64]; //�豸ID
}RJONE_PUSH_CMD_PHONE_DELETE_DEV;



////////����Ӧ�����ݽṹ////////

//IOCTRL_TYPE_GET_PUSH_PARAMETERS_REQ,
//IOCTRL_TYPE_GET_PUSH_PARAMETERS_RESP,

typedef struct _GET_PUSH_PARAMETERS_REQ
{		
	UINT8  u8Reserved[8];       
}RJONE_GET_PUSH_PARAMETERS_REQ;

typedef struct _GET_PUSH_PARAMETERS_RESP
{		
	INT32 s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��
	UINT8   u8EnablePush;		//PUSH ����ʹ��:   0 �ر�  1����
	UINT8   u8OpenDoorPush;		// ����������Ϣ:    0 �ر�  1����
	UINT8   u8PushExtraDataType;	//���͸�����Ϣ: �ο� RJONE_PUSH_EXTRA_DATA_TYPE
	UINT8    u8Reserved[9];	      
}RJONE_GET_PUSH_PARAMETERS_RESP;

	
//IOCTRL_TYPE_SET_PUSH_PARAMETERS_REQ,
//IOCTRL_TYPE_SET_PUSH_PARAMETERS_RESP,

typedef struct _SET_PUSH_PARAMETERS_REQ
{		
	UINT8   u8EnablePush;		//PUSH ����ʹ��:   0 �ر�  1����
	UINT8   u8OpenDoorPush;		// ����������Ϣ:    0 �ر�  1����
	UINT8   u8PushExtraDataType;	//���͸�����Ϣ: �ο� RJONE_PUSH_EXTRA_DATA_TYPE
	UINT8    u8Reserved[9];	   
}RJONE_SET_PUSH_PARAMETERS_REQ;

typedef struct _SET_PUSH_PARAMETERS_RESP
{		
	INT32    s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��
	UINT8    u8Reserved[8];	      
}RJONE_SET_PUSH_PARAMETERS_RESP;


//IOCTRL_TYPE_PUSH_EVENT_REQ,
//IOCTRL_TYPE_PUSH_EVENT_RESP,?
typedef struct _PUSH_EVENT_REQ
{		
	 // ����һ���豸����, 
	UINT8  u8Reserved[8];       
}RJONE_PUSH_EVENT_REQ;


typedef struct _PUSH_EVENT_RESP
{
	INT32 	s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��
	UINT8    u8Reserve[8];		
}RJONE_PUSH_EVENT_RESP;

//////////////////////////////////////////////////////////////////////////////////////////////////




/******************************************************************************************
								�豸�������ò���
*******************************************************************************************/

////////������ݽṹ////////


typedef struct  _RJONE_SYS_TIME_S_
{	
	RJONE_DAY_TIME  stSysTime;			// �豸ʱ��
	INT8		s8TimeZone;					// ʱ��
	UINT8	u8Reserve[3];
}RJONE_SYS_TIME_S;


typedef struct  _RJONE_SYS_TIME2_S_
{	
	RJONE_DAY_TIME  stSysTime;			// �豸ʱ��
	CHAR   strTimeZone[20];					// ʱ��GMT+8:00
	UINT8	u8Reserve[3];
}RJONE_SYS_TIME2_S;



typedef enum
{
	PASS_TYPE_UNKW,	 
	PASS_TYPE_DOOR,		//��������
	PASS_TYPE_NET_VIEW,   //����ۿ�����
}RJONG_PASS_TYPE;



////////����Ӧ�����ݽṹ////////


//IOCTRL_TYPE_GET_SYSFWVER_REQ,	
//IOCTRL_TYPE_GET_SYSFWVER_RESP,
typedef struct _GET_SYSFWVER_REQ
{		
	UINT8    u8Reserved[8];	
}RJONE_GET_SYSFWVER_REQ;


typedef struct _GET_SYSFWVER_RESP
{
	INT32 	s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��
	UINT32  u32VerFW;			//Ӳ���汾�� u32VerFW(UINT)   "Version: %d.%d.%d.%d", (u32VerFW & 0xFF000000)>>24, (u32VerFW & 0x00FF0000)>>16, (u32VerFW & 0x0000FF00)>>8, (u32VerFW & 0x000000FF) >> 0 )
	UINT32  u32VerSW;			//����汾�� u32VerSW(UINT)   "Version: %d.%d.%d.%d", (u32VerFW & 0xFF000000)>>24, (u32VerFW & 0x00FF0000)>>16, (u32VerFW & 0x0000FF00)>>8, (u32VerFW & 0x000000FF) >> 0 )
	UINT8    u8DevType;			// �ο�RJONE_DEV_TYPE
	UINT8    u8Reserved[7];	
}RJONE_GET_SYSFWVER_RESP;




//IOCTRL_TYPE_GET_DEV_TIME_REQ,
//IOCTRL_TYPE_GET_DEV_TIME_RESP,
typedef struct _GET_DEV_TIME_REQ
{		
	UINT8    u8Reserved[8];	
}RJONE_GET_DEV_TIME_REQ;


typedef struct _GET_DEV_TIME_RESP
{
	INT32 	s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	RJONE_SYS_TIME_S stSysTime;
	UINT8    u8Reserved[8];	
}RJONE_GET_DEV_TIME_RESP;


//IOCTRL_TYPE_SET_DEV_TIME_REQ,
//IOCTRL_TYPE_SET_DEV_TIME_RESP,
typedef struct _SET_DEV_TIME_REQ
{		
	RJONE_SYS_TIME_S stSysTime;
	UINT8    u8Reserved[8];
}RJONE_SET_DEV_TIME_REQ;


typedef struct _SET_DEV_TIME_RESP
{
	INT32 	s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��		
	UINT8    u8Reserved[8];
}RJONE_SET_DEV_TIME_RESP;



//IOCTRL_TYPE_CHANGE_DEV_PASSWORD_REQ,
//IOCTRL_TYPE_CHANGE_DEV_PASSWORD_RESP,
typedef struct _CHANGE_DEV_PASSWORD_REQ
{			
	CHAR    strOldPass[48];	// ԭ����
	CHAR    strNewPass[48];     // ������
	UINT8   u8PassType;     	 //�������ͣ��ο� RJONG_PASS_TYPE
	UINT8   u8Reserved[7];
}RJONE_CHANGE_DEV_PASSWORD_REQ;


typedef struct _CHANGE_DEV_PASSWORD_RESP
{
	INT32 	s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��		
	UINT8   u8Reserved[8];
}RJONE_CHANGE_DEV_PASSWORD_RESP;



//IOCTRL_TYPE_GET_DEV_INTERNET_FLAG_REQ,  
//IOCTRL_TYPE_GET_DEV_INTERNET_FLAG_RESP,  
typedef struct _GET_DEV_INTERNET_FLAG_REQ
{			
	UINT8    u8Reserved[8];
}RJONE_GET_DEV_INTERNET_FLAG_REQ;


typedef struct _GET_DEV_INTERNET_FLAG_RESP
{
	INT32 	s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	UINT8    u8EnableInernet;		// 0: ������internet.   1: ����internet
	UINT8    u8Reserved[7];
}RJONE_GET_DEV_INTERNET_FLAG_RESP;



//IOCTRL_TYPE_SET_DEV_INTERNET_FLAG_REQ,  
//IOCTRL_TYPE_SET_DEV_INTERNET_FLAG_RESP,  
typedef struct _SET_DEV_INTERNET_FLAG_REQ
{			
	UINT8    u8EnableInernet;		// 0: ������internet.   1: ����internet
	UINT8    u8Reserved[7];
}RJONE_SET_DEV_INTERNET_FLAG_REQ;


typedef struct _SET_DEV_INTERNET_FLAG_RESP
{
	INT32 	s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	UINT8    u8Reserved[8];
}RJONE_SET_DEV_INTERNET_FLAG_RESP;



/////////////////////////////////////////////////////////////////////////////////////////////////////



/******************************************************************************************
								ͼ���������
*******************************************************************************************/

////////������ݽṹ////////

typedef enum
{
	GAMMA_TYPE_DEFAULT = 0,
    	GAMMA_TYPE_0,
    	GAMMA_TYPE_1,
    	GAMMA_TYPE_2,   
    	GAMMA_TYPE_AUTO,  
}RJONE_GAMMA_TYPE;



////////����Ӧ�����ݽṹ////////
//IOCTRL_TYPE_GET_DEV_IMAGE_PARAMETERS_REQ,
//IOCTRL_TYPE_GET_DEV_IMAGE_PARAMETERS_RESP,
typedef struct _GET_DEV_IMAGE_PARAMETERS_REQ
{		
	UINT8    u8Reserved[8];
}RJONE_GET_DEV_IMAGE_PARAMETERS_REQ;


typedef struct _GET_DEV_IMAGE_PARAMETERS_RESP
{
	INT32 s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��
	UINT8  u8LumaVal;    			//���� [0 ~ 100]  Ĭ��ֵ 50.
	UINT8  u8ContrVal;    			//�Աȶ� [0 ~ 100]  Ĭ��ֵ 50.
	UINT8  u8HueVal;	      			//ɫ��� [0 ~ 100]  Ĭ��ֵ 50.	
	UINT8  u8SatuVal;      			//���Ͷ� [0 ~ 100]  Ĭ��ֵ 50.
	UINT8  u8Gamma;			// �ο�RJONE_GAMMA_TYPE
	UINT8  u8Mirror;			// ͼ��ˮƽ��תu8Mirror=1��ʾ��ת
	UINT8  u8Flip;			// ͼ��ֱ��תu8Flip =1 ��ʾ��ת
	UINT8    u8Reserved[9];
}RJONE_GET_DEV_IMAGE_PARAMETERS_RESP;


//IOCTRL_TYPE_SET_DEV_IMAGE_PARAMETERS_REQ,
//IOCTRL_TYPE_SET_DEV_IMAGE_PARAMETERS_RESP,
typedef struct _SET_DEV_IMAGE_PARAMETERS_REQ
{		
	UINT8  u8LumaVal;    		//���� [0 ~ 100]  Ĭ��ֵ 50.
	UINT8  u8ContrVal;    		//�Աȶ� [0 ~ 100]  Ĭ��ֵ 50.
	UINT8  u8HueVal;	      		//ɫ��� [0 ~ 100]  Ĭ��ֵ 50.	
	UINT8  u8SatuVal;      		//���Ͷ� [0 ~ 100]  Ĭ��ֵ 50.
	UINT8  u8Gamma;		// �ο�RJONE_GAMMA_TYPE
	UINT8  u8Mirror;			// ͼ��ˮƽ��תu8Mirror=1��ʾ��ת
	UINT8  u8Flip;			// ͼ��ֱ��תu8Flip =1 ��ʾ��ת
	UINT8    u8Reserved[9];
}RJONE_SET_DEV_IMAGE_PARAMETERS_REQ;


typedef struct _SET_DEV_IMAGE_PARAMETERS_RESP
{
	INT32    s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	UINT8    u8Reserved[8];
}RJONE_SET_DEV_IMAGE_PARAMETERS_RESP;


///////////////////////////////////////////////////////////////////////////////////////////////////////////



/******************************************************************************************
								��Ƶ��������
*******************************************************************************************/

////////������ݽṹ////////




////////����Ӧ�����ݽṹ////////
//IOCTRL_TYPE_GET_DEV_VIDEO_PARAMETERS_REQ,
//IOCTRL_TYPE_GET_DEV_VIDEO_PARAMETERS_RESP,
typedef struct _GET_DEV_VIDEO_PARAMETERS_REQ
{		
	UINT32 u32VideoChn;		//��Ƶ��ͨ���ţ�һ�� 0 Ϊ �������� 1Ϊ������
}RJONE_GET_DEV_VIDEO_PARAMETERS_REQ;


typedef struct _GET_DEV_VIDEO_PARAMETERS_RESP
{
	INT32 	s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��
	UINT8    u8VideoChn;		 //�������е�ͨ���š�һ�� 0 Ϊ��ͨ���� 1Ϊ��ͨ����
	UINT8   u8Code;     		 //ѹ����ʽ �ο�RJONE_CODE_TYPE
	UINT8   u8FrameRate;    	// 0-20 .   Ĭ��ֵΪ  20.
	UINT8   u8Gop;    		  	// I ֡��� �� Ĭ��ֵΪ 40	
	UINT32  u32BitRate;	       //ѹ������.  Ĭ��ֵΪ 2048 Kb/S
	UINT32  u32PicWidth;		// ��Ƶ�Ŀ�
	UINT32  u32PicHeight; 	// ��Ƶ�ĸߡ�
}RJONE_GET_DEV_VIDEO_PARAMETERS_RESP;



//IOCTRL_TYPE_SET_DEV_VIDEO_PARAMETERS_REQ,
//IOCTRL_TYPE_SET_DEV_VIDEO_PARAMETERS_RESP,
typedef struct _SET_DEV_VIDEO_PARAMETERS_REQ
{		
	UINT8    u8VideoChn;		 //�������е�ͨ���š�һ�� 0 Ϊ��ͨ���� 1Ϊ��ͨ����
	UINT8   u8Code;     		 //ѹ����ʽ �ο�RJONE_CODE_TYPE
	UINT8   u8FrameRate;    	// 0-20 .   Ĭ��ֵΪ  20.
	UINT8   u8Gop;    		  	// I ֡��� �� Ĭ��ֵΪ 40	
	UINT32  u32BitRate;	       //ѹ������.  Ĭ��ֵΪ 2048 Kb/S
	UINT32  u32PicWidth;		// ��Ƶ�Ŀ�
	UINT32  u32PicHeight; 	// ��Ƶ�ĸߡ�
	UINT8    u8Reserved[8];
}RJONE_SET_DEV_VIDEO_PARAMETERS_REQ;


typedef struct _SET_DEV_VIDEO_PARAMETERS_RESP
{
	INT32 	s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	UINT8    u8Reserved[8];
}RJONE_SET_DEV_VIDEO_PARAMETERS_RESP;

/////////////////////////////////////////////////////////////////////////////////////////////




/******************************************************************************************
								��������
*******************************************************************************************/

////////������ݽṹ////////


////////����Ӧ�����ݽṹ////////
//IOCTRL_TYPE_GET_DEVICE_ALARM_REQ,
//IOCTRL_TYPE_GET_DEVICE_ALARM_RESP,
typedef struct _GET_DEVICE_ALARM_REQ
{	
	UINT8    u8Reserved[8];
}RJONE_GET_DEVICE_ALARM_REQ;


typedef struct _GET_DEVICE_ALARM_RESP
{
	INT32 	s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��		
	UINT8 u8Enable;			//  1: �������� 0:�����ر�
	UINT8 u8AlarmRecord;	//  �������Ƿ�����¼�� 1:����  0:������
	UINT8 u8Snap;			// �������Ƿ�����ץ�ġ�  1:����  0:������
	UINT8 u8Push;			// �������Ƿ��������͡�  1:����  0:������
	UINT8 u8Reserved[8];
}RJONE_GET_DEVICE_ALARM_RESP;



//IOCTRL_TYPE_SET_DEVICE_ALARM_REQ,
//IOCTRL_TYPE_SET_DEVICE_ALARM_RESP,
typedef struct _SET_DEVICE_ALARM_REQ
{	
	UINT8 u8Enable;			//  1: �������� 0:�����ر�
	UINT8 u8AlarmRecord;	//  �������Ƿ�����¼�� 1:����  0:������
	UINT8 u8Snap;			// �������Ƿ�����ץ�ġ�  1:����  0:������
	UINT8 u8Push;			// �������Ƿ��������͡�  1:����  0:������
	UINT8 u8Reserved[8];
}RJONE_SET_DEVICE_ALARM_REQ;


typedef struct _SET_DEVICE_ALARM_RESP
{
	INT32 	s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��			
	UINT8    u8Reserved[8];
}RJONE_SET_DEVICE_ALARM_RESP;

////////////////////////////////////////////////////////////////////////////////////////////


/******************************************************************************************
								¼���������
*******************************************************************************************/

////////������ݽṹ////////

typedef enum 
{
	FILE_FORMAT_NONE    = 0, 
	FILE_FORMAT_AVI, 		
	FILE_FORMAT_MP4, 
}RJONG_FILE_FORMAT;




////////����Ӧ�����ݽṹ////////
//IOCTRL_TYPE_GET_RECORD_PARAMETERS_REQ,
//IOCTRL_TYPE_GET_RECORD_PARAMETERS_RESP,
typedef struct _GET_RECORD_PARAMETERS_REQ
{	
	UINT8    u8Reserved[8];
}RJONE_GET_RECORD_PARAMETERS_REQ;


typedef struct _GET_RECORD_PARAMETERS_RESP
{	
	INT32 	s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��
	UINT32 u32RecordTimeSec;				//  �д����¼�ʱ��¼�������¼��	
	UINT8   u8RecordFileFormat;			//  ¼���ļ���ʽ ���ο� RJONG_FILE_FORMAT
	UINT8    u8Reserved[7];
}RJONE_GET_RECORD_PARAMETERS_RESP;




//IOCTRL_TYPE_SET_RECORD_PARAMETERS_REQ,
//IOCTRL_TYPE_SET_RECORD_PARAMETERS_RESP,
typedef struct _SET_RECORD_PARAMETERS_REQ
{	
	UINT32 u32RecordTimeSec;				//  �д����¼�ʱ��¼�������¼��	
	UINT8   u8RecordFileFormat;			//  ¼���ļ���ʽ ���ο� RJONG_FILE_FORMAT
	UINT8    u8Reserved[7];	
}RJONE_SET_RECORD_PARAMETERS_REQ;


typedef struct _SET_RECORD_PARAMETERS_RESP
{
	INT32 	s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	UINT8    u8Reserved[8];
}RJONE_SET_RECORD_PARAMETERS_RESP;


///////////////////////////////////////////////////////////////////////////////////////////



/******************************************************************************************
								��֤���� &  ��Ȩ
*******************************************************************************************/

////////������ݽṹ////////



////////����Ӧ�����ݽṹ////////
//IOCTRL_TYPE_AUTHORIZE_REQ, 
//IOCTRL_TYPE_AUTHORIZE_RESP,
typedef struct _AUTHORIZE_REQ
{		
	CHAR  strPassWord[48];	     //��д�ۿ�����
	UINT8 u8Reserved[8];
}RJONE_AUTHORIZE_REQ;

typedef struct _AUTHORIZE_RESP
{
       INT32 	s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��		
	UINT8 u8ValueReq; 			//=IOCTRLSetAuthorizeReq.value	
	UINT8 u8Reserved[7];
}RJONE_AUTHORIZE_RESP;

///////////////////////////////////////////////////////////////////////////////////////////////


/******************************************************************************************
								�豸����
*******************************************************************************************/


////////������ݽṹ////////
typedef enum {
	UPGRADE_DATA_FIRST,		//App to Device, begin to transfer upgrade pakcet data
	UPGRADE_DATA_MID,		//App to Device, middle data of upgrade pakcet
	UPGRADE_DATA_END,		//App to Device, complete transfer.
}RJONE_ENUM_UPGRADE_DATA_TYPE;




//IOCTRL_TYPE_UPGRADE_READY,		//Device to App, Device is ready for receiving upgrade firmware. App begin to send data
typedef struct
{
	INT8  result;                  			 //0: ready; 1: wrong device password
	UINT8 reserved[3];
}RJONE_UPGREDE_RESP;


//for Upgrade firmware
typedef struct{
	UINT16 nUpgradeDataType;             //refer to RJONE_ENUM_UPGRADE_DATA_TYPE
	UINT16 nUpgradeDataSize;
	UINT32 nCRC;
   	CHAR  uDevPasswd[24];                  //end user upgrad firmware need input passward.
 	UINT8  bNeedDevPasswd;               //0: no need, 1:need verfy device password   
	UINT8  reserve[7];
}RJONE_UPGRADE_HEAD;


typedef struct
{
	UINT8  nouse[2]; //default: PK
	UINT8  dev_type;  // 1: single sensor; 2:dual sensor //2013-03-09
	UINT8  reserve1;
	UINT8  verThisBin[4]; 	// 1.2.3.4, verThisBin[0,1,2,3]=0x04,0x03,0x02,0x01
	UINT32 sizeThisBin;
	UINT8  flag[4];	      //default: P2PU
	UINT8  reserve2[8];
}RJONE_UPGRADE_FILE_HEAD;


////////����Ӧ�����ݽṹ////////


//IOCTRL_TYPE_UPGRADE_REQ,		//App to Device
// data: upgrade file size

//IOCTRL_TYPE_UPGRADE_READY,		//Device to App, Device is ready for receiving upgrade firmware. App begin to send data
// no data

//IOCTRL_TYPE_UPGRADE_QUERY,	//App to Device, Query device to upgrade firmware ok ? after sending upgrade data over
// no data

//IOCTRL_TYPE_UPGRADE_OK,			//Device to App
// no data

//IOCTRL_TYPE_UPGRADE_FAILED,		//Device to App
// no data

//IOCTRL_TYPE_GET_SN_ETC_REQ	//App to Device
// no data





//////////////////////////////////////////////////////////////////////////////////////////////////


/******************************************************************************************
								��������
*******************************************************************************************/

////////������ݽṹ////////



////////����Ӧ�����ݽṹ////////
//IOCTRL_TYPE_DOORBELL_OPEN_REQ,             
//IOCTRL_TYPE_DOORBELL_OPEN_RESP, 
typedef struct _DOORBELL_OPEN_REQ
{		
	UINT8	u8DoorBellOpen;           // 1. Open   0. No work;
	UINT8    u8Reserved[7];
}RJONE_DOORBELL_OPEN_REQ;


typedef struct DOORBELL_OPEN_RESP
{
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	UINT8 u8Reserved[8];
}RJONE_DOORBELL_OPEN_RESP;


//////////////////////////////////////////////////////////////////////////////////////////////////



/******************************************************************************************
								SD�� TF�� ����
*******************************************************************************************/

////////������ݽṹ////////



////////����Ӧ�����ݽṹ////////

//IOCTRL_TYPE_SET_DEVICE_SDFORMAT_REQ,
//IOCTRL_TYPE_SET_DEVICE_SDFORMAT_RESP,
typedef struct _SET_DEVICE_SDFORMAT_REQ
{			
	UINT8    u8Reserved[8];
}RJONE_SET_DEVICE_SDFORMAT_REQ;


typedef struct SET_DEVICE_SDFORMAT_RESP
{
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	UINT8 u8Reserved[8];
}RJONE_SET_DEVICE_SDFORMAT_RESP;


//IOCTRL_TYPE_SDFORMAT_QUERY_REQ,
//IOCTRL_TYPE_SDFORMAT_QUERY_RESP,
typedef struct _SDFORMAT_QUERY_REQ
{		
	UINT8 u8Reserved[8];
}RJONE_SDFORMAT_QUERY_REQ;


typedef struct _SDFORMAT_QUERY_RESP
{
	INT32    s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	INT8     s8QueryResult;           // 1: ���ڸ�ʽ����-1 ��ʽ��ʧ�ܣ�0.��ʽ�����
	UINT8    u8Reserved[7];
}RJONE_SDFORMAT_QUERY_RESP;


//IOCTRL_TYPE_GET_SD_INFO_REQ,
//IOCTRL_TYPE_GET_SD_INFO_RESP,
typedef struct _GET_SD_INFO_REQ
{		
	UINT8 u8Reserved[8];
}RJONE_GET_SD_INFO_REQ;


typedef struct GET_SD_INFO_RESP
{
	INT32    s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	UINT32  u32SDSize;			//  SD ����������С����λ K bytes.
	UINT32  u32UseSize;			// SD��ʹ���˵Ŀռ��С  K bytes.
	UINT32  u32AvailableSize;       // SD��δʹ�õĿռ��С  K bytes.
	UINT8 u8Reserved[8];
}RJONE_GET_SD_INFO_RESP;


//	IOCTRL_TYPE_GET_RTSP_INFO_REQ,
//	IOCTRL_TYPE_GET_RTSP_INFO_RESP,
typedef struct _GET_RTSP_INFO_REQ
{		
	UINT8 u8Reserved[8];
}RJONE_GET_RTSP_INFO_REQ;


typedef struct GET_RTSP_INFO_RESP
{
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	CHAR  stUrl[2][50];			// ���� rtsp �ĵ�ַ��
	UINT8 u8VideoCode;		//��Ƶѹ����ʽ RJONE_CODE_TYPE
	UINT8 u8AudioCode;		//��Ƶѹ����ʽ RJONE_CODE_TYPE
	UINT8 u8AudioSamplerate;				//������ RJONE_AUDIO_SAMPLERATE
	UINT8 u8AudioBits;						//����λ��RJONE_AUDIO_DATABITS
	UINT8 u8AudioChannel;					//ͨ��		RJONE_AUDIO_CHANNEL					
	UINT8 u8Reserved[78];
}RJONE_GET_RTSP_INFO_RESP;


//IOCTRL_TYPE_GET_PERIPHERAL_EQUIPMENT_INFO_REQ,
//IOCTRL_TYPE_GET_PERIPHERAL_EQUIPMENT_INFO_RESP,
typedef struct _GET_PERIPHERAL_EQUIPMENT_INFO_REQ
{		
	UINT8 u8Reserved[8];
}RJONE_GET_PERIPHERAL_EQUIPMENT_INFO_REQ;

typedef struct _GET_PERIPHERAL_EQUIPMENT_INFO_RESP
{		
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	UINT8 u8TemperatureF;   //�����¶�
	UINT8 u8TemperatureC;   //�����¶�
	UINT8 u8PtzHorizontal;	//��̨ˮƽλ�ƽǶ� (��Χ0~120)����δ������
	UINT8 u8PtzVertical;		//��̨��ֱλ�ƽǶ� (��Χ0~120).    ��δ������
	UINT8 u8Reserved[8];
}RJONE_GET_PERIPHERAL_EQUIPMENT_INFO_RESP;



//IOCTRL_TYPE_GET_FREQUENCY_INFO_REQ,
//IOCTRL_TYPE_GET_FREQUENCY_INFO_RESP,

//IOCTRL_TYPE_SET_FREQUENCY_INFO_REQ,
//IOCTRL_TYPE_SET_FREQUENCY_INFO_RESP,

typedef enum 
{
    RJONE_VIDEO_ENCODING_MODE_PAL_50HZ=0,
    RJONE_VIDEO_ENCODING_MODE_NTSC_60HZ,
    RJONE_VIDEO_ENCODING_MODE_AUTO,
    RJONE_VIDEO_ENCODING_MODE_BUTT
}RJONE_VIDEO_NORM_E;




typedef enum 
{
    RJONE_WDR_MODE_NONE = 0,
    RJONE_WDR_MODE_BUILT_IN,

    RJONE_WDR_MODE_2To1_LINE,
    RJONE_WDR_MODE_2To1_FRAME,
    RJONE_WDR_MODE_2To1_FRAME_FULL_RATE,

    RJONE_WDR_MODE_3To1_LINE,
    RJONE_WDR_MODE_3To1_FRAME,
    RJONE_WDR_MODE_3To1_FRAME_FULL_RATE,

    RJONE_WDR_MODE_4To1_LINE,
    RJONE_WDR_MODE_4To1_FRAME,
    RJONE_WDR_MODE_4To1_FRAME_FULL_RATE,

    RJONE_WDR_MODE_BUTT,
} RJONE_WDR_MODE_E;


typedef struct _GET_FREQUENCY_INFO_REQ
{		
	UINT8 u8Reserved[8];
}RJONE_GET_FREQUENCY_INFO_REQ;

typedef struct _GET_FREQUENCY_INFO_RESP
{		
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	UINT8 u8Frequency;  		//�ο� RJONE_VIDEO_NORM_E
	UINT8 u8Reserved[7];
}RJONE_GET_FREQUENCY_INFO_RESP;


typedef struct _SET_FREQUENCY_INFO_REQ
{		
	UINT8 u8Frequency;  		//�ο� RJONE_VIDEO_NORM_E
	UINT8 u8Reserved[7];
}RJONE_SET_FREQUENCY_INFO_REQ;

typedef struct _SET_FREQUENCY_INFO_RESP
{		
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	UINT8 u8Reserved[8];
}RJONE_SET_FREQUENCY_INFO_RESP;


/******************************************************************************************
							�г���¼�ǲ���
*******************************************************************************************/

////////������ݽṹ////////

typedef enum {
	DC_FILE_TYPE_VIDEO,		
	DC_FILE_TYPE_GPS,		
	DC_FILE_TYPE_SNAP_PIC,	
	DC_FILE_TYPE_THUMBNAIL_PIC,
	DC_FILE_TYPE_SNAP_VIDEO,	
	DC_FILE_TYPE_EMERGENCY_VIDEO,
	DC_FILE_TYPE_BUFF,
}RJONE_DC_ENUM_FILE_TYPE;


typedef enum {
	DC_PLAY_MODE_FILE,		
	DC_PLAY_MODE_TIME,
	DC_PLAY_MODE_BUFF,
}RJONE_DC_PLAY_MODE;


typedef enum {
	DC_PLAY_START,		
	DC_PLAY_STOP,
	DC_PLAY_PAUSE,
	DC_PLAY_RESUME,
	DC_PLAY_SEEK_FORWARD,
	DC_PLAY_SEEK_BACK,
	DC_PLAY_SEEK_POS,
}RJONE_DC_PLAY_CTRL;


typedef enum {
	DC_EXTERNAL_GPS_DATA,		
	DC_EXTERNAL_OBD_DATA,
	DC_EXTERNAL_BUFF,
}RJONE_DC_SEND_EXTERNAL_DATA;


typedef struct _DC_EXTERNAL_GPS_INFO_
{	
	UINT32 u32TimeDay;    // ���� 20151224 -> 2015/12/24
	UINT32 u32Time;	      //  ʱ�� 115500   -> 11:55:00	
	float longitude;		//����
	float latitude;			//γ��
	float speed;			//�ٶ�km/s
	float altitude;			//�߶�m
	UINT8 u8Reserved[32];
}RJONE_DC_EXTERNAL_GPS_INFO;

typedef struct _DC_EXTERNAL_OBD_INFO_
{
	UINT32 u32TimeDay;    // ���� 20151224 -> 2015/12/24
	UINT32 u32Time;	      //  ʱ�� 115500   -> 11:55:00	
	float oil_temperature;            //����
	float water_temperature;	//ˮ��
	float speed;				//���� km/s
	float engine_revolutions;	//�����ת�� r/min
	float avg_oil_consumption;   //ƽ���ͺ�	KM/L
	float Instant_oil_consumption; //˲���ͺ�   KM/L
	float oil_capacity;			//ʣ������	L
	float voltage;				//��ƽ��ѹ	V
	float engine_load;				//���������� %
	float engine_failure;		//���������ϣ�0�Ǳ�ʾ��������������ֵ���ǹ��ϴ���.
//add 2016.2.15. radar
	float charge_failure;	//����·�쳣
	float coolant_temperature;	//��ȴҺ�¶�
	float mileage;	//��ʻ���
//end 2016.2.15 append	
	UINT8 u8Reserved[16];
}RJONE_DC_EXTERNAL_OBD_INFO;


typedef struct _DC_EXTERNAL_DATA_INFO
{
	UINT8 u8ExternalDataType;	 //�ⲿ���ݵ����ͣ��ο� RJONE_DC_SEND_EXTERNAL_DATA
	UINT8 u8Reserved[7];
	union
	{
		RJONE_DC_EXTERNAL_GPS_INFO  stGpsInfo;
		RJONE_DC_EXTERNAL_OBD_INFO stOBDInfo;
	};
}RJONE_DC_EXTERNAL_DATA_INFO;


typedef struct _DC_FILE_INFO_
{
	CHAR strFileName[52];	//�ļ���
	UINT32 u32FileSize;       //�ļ�����
	UINT32 u32Duration;      //�ļ�����ʱ��
	UINT8 u8Reserved[8];
}RJONE_DC_FILE_INFO;

//�ļ���ѯ
//IOCTRL_TYPE_DC_GET_FILE_LIST_REQ,
//IOCTRL_TYPE_DC_GET_FILE_LIST_RESP,

typedef struct _DC_GET_FILE_LIST_REQ
{		
	UINT32 u32SearchTime;         //����ʱ�� ������u32SearchTime = 20150818
	UINT8 u8FileType;  		//�ο� RJONE_DC_ENUM_FILE_TYPE
	UINT8 u8Reserved[7];
}RJONE_DC_GET_FILE_LIST_REQ;

typedef struct _DC_GET_FILE_LIST_RESP
{		
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��
	UINT32 u32TotalFileNum;  		//�����������ļ�����
	UINT8 u8FileType;  		//�ο� RJONE_DC_ENUM_FILE_TYPE
	UINT8 u8Reserved[3];
	UINT32 u32SearchTime; 	//��������ʱ��
	RJONE_DC_FILE_INFO  stFileInfoArray[0];
}RJONE_DC_GET_FILE_LIST_RESP;


//���´洢��Ϣ��ѯ
//IOCTRL_TYPE_DC_CHECK_SAVE_INFO_BY_MONTH_REQ,   //��ѯһ��������Щ���д洢����
//IOCTRL_TYPE_DC_CHECK_SAVE_INFO_BY_MONTH_RESP,

typedef struct _DC_CHECK_SAVE_INFO_BY_MONTH_REQ
{		
	UINT32 u32SearchTime;         //����ʱ�� ������u32SearchTime = 20150800 ��ѯ2015��8�µ�����
	UINT8 u8FileType;  		//�ο� RJONE_DC_ENUM_FILE_TYPE
	UINT8 u8Reserved[7];
}RJONE_DC_CHECK_SAVE_INFO_BY_MONTH_REQ;

typedef struct _DC_CHECK_SAVE_INFO_BY_MONTH_RESP
{		
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��
	UINT32 u32SaveFileDay;  		// ��bit λ��ȷ�ϵ����Ƿ��д洢���ݣ�bitλ(0 - 30) �����ʾ1��-- 31�����ڣ�
								//bit0 ==1 ʱ����ʾ1���д洢����,bit30 == 0ʱ��ʾ31������û�д洢���ݡ�
	UINT8 u8FileType; 			//�ο� RJONE_DC_ENUM_FILE_TYPE
	UINT8 u8Reserved[3];	
	UINT32 u32SearchTime;	 	//��������ʱ��
}RJONE_DC_CHECK_SAVE_INFO_BY_MONTH_RESP;





//�����ļ�
//	IOCTRL_TYPE_DC_DELETE_FILE_REQ,
//	IOCTRL_TYPE_DC_DELETE_FILE_RESP,


typedef struct _DC_DELETE_FILE_REQ
{		
	CHAR strFileName[52];	//ȫ·�����ļ��������� /mnt/sdcard/rec/20150816/20150816_152032.mp4	
	UINT8 u8Reserved[8];
}RJONE_DC_DELETE_FILE_REQ;


typedef struct _DC_DELETE_FILE_RESP
{		
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	UINT8 u8Reserved[8];
}RJONE_DC_DELETE_FILE_RESP;




//�����ļ�
//	IOCTRL_TYPE_DC_DOWNLOAD_FILE_REQ,
//	IOCTRL_TYPE_DC_DOWNLOAD_FILE_RESP,

//��ʱ��������ǰ�����ط�ʽ

typedef struct _DC_DOWNLOAD_FILE_REQ
{		
	CHAR strFileName[52];	//ȫ·�����ļ��������� /mnt/sdcard/rec/20150816/20150816_152032.mp4
	UINT32 u32FileStartOffset;   //�ļ�ƫ�Ƶ㣬����ָ�����ļ��ĸ�λ�ÿ�ʼ���أ�֧���ļ�������
	UINT16 u16FileInTar;    //����tar �ļ�ʱ������ָ�����ش���ļ��еļ����ļ���
						// u16FileInTar = 0ʱȫ������, u16FileInTar�����ļ�����ʱ��ȫ�����ء�
						// u16FileInTar ��u32FileStartOffset ��������������ͬʱ�����á�
						// ��u32FileStartOffset  != 0ʱ��u16FileInTarʧЧ��
	UINT8 u8Reserved[6];
}RJONE_DC_DOWNLOAD_FILE_REQ;


typedef struct _DC_DOWNLOAD_FILE_RESP
{		
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��
	CHAR strFileName[52];	//ȫ·�����ļ��������� /mnt/sdcard/rec/20150816/20150816_152032.mp4
	UINT32 u32FileStartOffset;   //�ļ�����λ�á�
	UINT16 u16SessionId;		//�������кţ�ͬһ��������˱����ͬ��
	UINT8 u8Reserved[6];
}RJONE_DC_DOWNLOAD_FILE_RESP;


//���߻ط�
//	IOCTRL_TYPE_DC_ONLINE_PLAY_FILE_REQ,
//	IOCTRL_TYPE_DC_ONLINE_PLAY_FILE_RESP,	


typedef struct _DC_ONLINE_PLAY_FILE_REQ
{		
	CHAR strFileName[52];	//ȫ·�����ļ��������� /mnt/sdcard/rec/20150816/20150816_152032.mp4  �� u8PlayMode = DC_PLAY_MODE_FILE ʱ�����á�
	UINT32 u32TimePos;   //��ʱ��㲥����Ƶ�� u8PlayMode = DC_PLAY_MODE_TIME ʱ�����á�
	UINT8 u8PlayMode;      //�ο�RJONE_DC_PLAY_MODE
	UINT8 u8Reserved[7];
}RJONE_DC_ONLINE_PLAY_FILE_REQ;


typedef struct _DC_ONLINE_PLAY_FILE_RESP
{	
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	UINT32 s32FilePlaySec;		//���ز����ļ�������ʱ�䣬��λ���롣
	UINT16 u16SessionId;		//�������кţ�ͬһ��������˱����ͬ��
	UINT8 u8Reserved[6];
}RJONE_DC_ONLINE_PLAY_FILE_RESP;


//��ʱ��������ǰ�Ĳ��ŷ�ʽ
//	IOCTRL_TYPE_DC_ONLINE_PLAY_CTRL_REQ,
//	IOCTRL_TYPE_DC_ONLINE_PLAY_CTRL_RESP,
/*
typedef struct _DC_ONLINE_PLAY_CTRL_REQ
{	
	UINT8 u8PlayCtrl;			//�ο�RJONE_DC_PLAY_CTRL
	UINT8 u8Reserved[7];
}RJONE_DC_ONLINE_PLAY_CTRL_REQ;

typedef struct _DC_ONLINE_PLAY_CTRL_RESP
{	
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	UINT8 u8Reserved[8];
}RJONE_DC_ONLINE_PLAY_CTRL_RESP;
*/


//ʵʱ����
//	IOCTRL_TYPE_DC_SNAP_REQ,
//	IOCTRL_TYPE_DC_SNAP_RESP,

typedef struct _DC_SNAP_REQ
{		
	UINT8 u8CreateSnapVideo;  //ץ��ʱ�Ƿ����ץ��¼�� u8CreateSnapVideo = 1 ��ʾ����¼���ļ���u8CreateSnapVideo = 0��ʾ������¼���ļ���
	UINT8 u8Reserved[7];
}RJONE_DC_SNAP_REQ;

typedef struct _DC_SNAP_RESP
{	
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	UINT8 u8Reserved[8];
}RJONE_DC_SNAP_RESP;


//���ӹ�
//IOCTRL_TYPE_DC_ELECTRONIC_DOG_GET_REQ,
//IOCTRL_TYPE_DC_ELECTRONIC_DOG_GET_RESP,
	
//IOCTRL_TYPE_DC_ELECTRONIC_DOG_SET_REQ,
//IOCTRL_TYPE_DC_ELECTRONIC_DOG_SET_RESP,

typedef struct _DC_ELECTRONIC_DOG_GET_REQ
{			
	UINT8 u8Reserved[8];
}RJONE_DC_ELECTRONIC_DOG_GET_REQ;

typedef struct _DC_ELECTRONIC_DOG_GET_RESP
{	
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	UINT8 u8ElectronicDowIsWork;  //���ӹ��Ƿ��ڹ���״̬, u8ElectronicDowIsWork = 1 ��ʾ���ڹ�����
	UINT8 u8Reserved[7];
}RJONE_DC_ELECTRONIC_DOG_GET_RESP;


typedef struct _DC_ELECTRONIC_DOG_SET_REQ
{			
	UINT8 u8ElectronicDowIsWork;  //���õ��ӹ�����״̬, u8ElectronicDowIsWork = 1 ��ʾ������
	UINT8 u8Reserved[7];
}RJONE_DC_ELECTRONIC_DOG_SET_REQ;

typedef struct _DC_ELECTRONIC_DOG_SET_RESP
{	
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��		
	UINT8 u8Reserved[8];
}RJONE_DC_ELECTRONIC_DOG_SET_RESP;



//���ô����ٶ�
//IOCTRL_TYPE_DC_SET_UART_REQ,
//IOCTRL_TYPE_DC_SET_UART_RESP,

//���󴮿ڿ���
//IOCTRL_TYPE_DC_REQUEST_UART_CTRL_REQ,
//IOCTRL_TYPE_DC_REQUEST_UART_CTRL_RESP,	

typedef struct _DC_SET_UART_REQ
{			
	INT32 s32Speed;        //���ڲ�����  2400  4800 9600 19200  58400  115200
	UINT8 u8Reserved[8];
}RJONE_DC_SET_UART_REQ;

typedef struct _DC_SET_UART_RESP
{	
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��		
	UINT8 u8Reserved[8];
}RJONE_DC_SET_UART_RESP;


typedef struct _DC_REQUEST_UART_CTRL_REQ
{				
	UINT8 u8Reserved[8];
}RJONE_DC_REQUEST_UART_CTRL_REQ;

typedef struct _DC_REQUEST_UART_CTRL_RESP
{	
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��		
	UINT8 u8Reserved[8];
}RJONE_DC_REQUEST_UART_CTRL_RESP;



//�������ݷ���   �豸-> app
//IOCTRL_TYPE_DC_SEND_UART_DATA_REQ,
//IOCTRL_TYPE_DC_SEND_UART_DATA_RESP,

typedef struct _DC_SEND_UART_DATA_REQ
{			
	INT32 s32DataLen;        //�������ݳ���
	UINT8 u8Reserved[8];
	UINT8 u8UartData[0];
}RJONE_DC_SEND_UART_DATA_REQ;

typedef struct _SEND_UART_DATA_RESP
{	
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��		
	UINT8 u8Reserved[8];
}RJONE_SEND_UART_DATA_RESP;



//�������ݽ���   app -> �豸
//IOCTRL_TYPE_DC_WRITE_UART_DATA_REQ,
//IOCTRL_TYPE_DC_WRITE_UART_DATA_RESP,

typedef struct _DC_WRITE_UART_DATA_REQ
{			
	INT32 s32DataLen;        //�������ݳ���
	UINT8 u8Reserved[8];
	UINT8 u8UartData[0];
}RJONE_DC_WRITE_UART_DATA_REQ;

typedef struct _DC_WRITE_UART_DATA_RESP
{	
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��		
	UINT8 u8Reserved[8];
}RJONE_DC_WRITE_UART_DATA_RESP;



//IOCTRL_TYPE_DC_STOP_DOWNLOAD_FILE_REQ,
//IOCTRL_TYPE_DC_STOP_DOWNLOAD_FILE_RESP,
typedef struct _DC_STOP_DOWNLOAD_FILE_REQ
{			
	UINT16 u16SessionId;		//�������к�,�˲���δ������չ�ã�Ŀǰ�� u16SessionId = 0 �Ϳ����ˡ�
	UINT8 u8Reserved[6];	
}RJONE_DC_STOP_DOWNLOAD_FILE_REQ;

typedef struct _DC_STOP_DOWNLOAD_FILE_RESP
{	
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��		
	UINT8 u8Reserved[8];
}RJONE_DC_STOP_DOWNLOAD_FILE_RESP;



//��ȡ�汾�Žӿ�2
//IOCTRL_TYPE_GET_DEVAPPVER_REQ,	
//IOCTRL_TYPE_GET_DEVAPPVER_RESP,
typedef struct _GET_DEVAPPVER_REQ
{			
	UINT8 u8Reserved[8];	
}RJONE_GET_DEVAPPVER_REQ;

typedef struct _GET_DEVAPPVER_RESP
{	
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	UINT8  u8Ver[64];			//�汾��
	UINT8 u8Reserved[8];
}RJONE_GET_DEVAPPVER_RESP;


//ʱ�����ýӿ�2
//IOCTRL_TYPE_GET_DEV_TIME2_REQ,
//IOCTRL_TYPE_GET_DEV_TIME2_RESP,

//IOCTRL_TYPE_SET_DEV_TIME2_REQ,
//IOCTRL_TYPE_SET_DEV_TIME2_RESP,

typedef struct _GET_DEV_TIME2_REQ
{		
	UINT8    u8Reserved[8];	
}RJONE_GET_DEV_TIME2_REQ;


typedef struct _GET_DEV_TIME2_RESP
{
	INT32 	s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	RJONE_SYS_TIME2_S stSysTime;
	UINT8    u8Reserved[8];	
}RJONE_GET_DEV_TIME2_RESP;


typedef struct _SET_DEV_TIME2_REQ
{		
	RJONE_SYS_TIME2_S stSysTime;
	UINT8    u8Reserved[8];
}RJONE_SET_DEV_TIME2_REQ;


typedef struct _SET_DEV_TIME2_RESP
{
	INT32 	s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��		
	UINT8      u8Reserved[8];
}RJONE_SET_DEV_TIME2_RESP;


//�ϴ�ץ��ͼƬ����Ƶ�ļ�����Ϣ
//IOCTRL_TYPE_SEND_SNAP_FILE_INFO_REQ,
//IOCTRL_TYPE_SEND_SNAP_FILE_INFO_RESP,

typedef struct _SEND_SNAP_FILE_INFO_REQ
{		
	UINT8 u8FileType;  		//�ο� RJONE_DC_ENUM_FILE_TYPE
	CHAR strFileName[80];		//�ļ���
}RJONE_SEND_SNAP_FILE_INFO_REQ;


typedef struct _SEND_SNAP_FILE_INFO_RESP
{
	INT32 	s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	UINT8    u8Reserved[8];	
}RJONE_SEND_SNAP_FILE_INFO_RESP;



//������ʱ��������
//IOCTRL_TYPE_DC_CREATE_TMP_CONNECT_PASSWORD_REQ,
//IOCTRL_TYPE_DC_CREATE_TMP_CONNECT_PASSWORD_RESP,

typedef struct _DC_CREATE_TMP_CONNECT_PASSWORD_REQ
{		
	INT32    s32AllowConnectNum;  		//�����������Ӷ��ٴε�����
	UINT32  s32AllowConnectSeconds;	//�������ӳ����Ķ������ӣ�����ָ���������󣬻������Զ��Ͽ����ӡ�
									// s32AllowConnectSeconds = 0 ʱ��ʾ�������ơ�
	UINT8    u8Reserved[28];	;			//�ļ���
}RJONE_DC_CREATE_TMP_CONNECT_PASSWORD_REQ;


typedef struct _DC_CREATE_TMP_CONNECT_PASSWORD_RESP
{
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	CHAR   strTmpAccessPass[64];		//��������ʱ����
	UINT8  u8Reserved[32];	
}RJONE_DC_CREATE_TMP_CONNECT_PASSWORD_RESP;


//�ϴ�ɾ���ļ�����Ϣ mac -> app
//IOCTRL_TYPE_SEND_DEL_FILE_INFO_REQ,
//IOCTRL_TYPE_SEND_DEL_FILE_INFO_RESP,


typedef struct _SEND_DEL_FILE_INFO_REQ
{		
	UINT8 u8FileType;  		//�ο� RJONE_DC_ENUM_FILE_TYPE
	CHAR strFileName[80];		//�ļ���
}RJONE_SEND_DEL_FILE_INFO_REQ;


typedef struct _SEND_DEL_FILE_INFO_RESP
{
	INT32 	s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	UINT8    u8Reserved[8];	
}RJONE_SEND_DEL_FILE_INFO_RESP;


//��ȡtf ���Ͼ����ļ���Ϣ
//IOCTRL_TYPE_DC_GET_TFCARD_INFO_REQ,
//IOCTRL_TYPE_DC_GET_TFCARD_INFO_RESP,


typedef struct _DC_GET_TFCARD_INFO_REQ
{		
	UINT8    u8Reserved[8];	
}RJONE_DC_GET_TFCARD_INFO_REQ;


typedef struct _DC_GET_TFCARD_INFO_RESP
{
	INT32    s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��,
	UINT32  u32SDSize;			//  SD ����������С���������Ե�λ����M bytes.
	UINT32  u32UseSize;			// SD��ʹ���˵Ŀռ��С.
	UINT32  u32AvailableSize;       // SD��δʹ�õĿռ��С  .   
	UINT32  u32OtherFileSize;		//SD���������ļ��Ĵ�С����Щ�ļ������ǵ�ϵͳ����� .
	UINT32  u32VideoAllowUseSize;	//��ͨ¼���ܴ洢�ռ��С .
	UINT32  u32VideoUseSize;			// ��ͨ¼��ʹ���˵Ŀռ��С  .	
	UINT32  u32SnapAllowUseSize;		//ץ��ͼƬ¼���ܴ洢�ռ��С.
	UINT32  u32SnapPicUseSize;			// ץ��ͼƬʹ���˵Ŀռ��С  .
	UINT32  u32SnapVideoUseSize;			// ץ��¼��ʹ���˵Ŀռ��С  .
	UINT32  u32SnapAvailableSize;       	// ��ͨ¼��δʹ�õĿռ��С  .   
	UINT32  u32EmergencyAllowUseSize;		//ץ��ͼƬ¼���ܴ洢�ռ��С.
	UINT32  u32EmergencyVideoUseSize;			// ץ��¼��ʹ���˵Ŀռ��С .	
	UINT8    u8Reserved[32];	
}RJONE_DC_GET_TFCARD_INFO_RESP;



//�����豸��APP ����ʵʱGPS+OBD������
//IOCTRL_TYPE_GET_GPS_OBD_SEND_PARAMETERS_REQ,
//IOCTRL_TYPE_GET_GPS_OBD_SEND_PARAMETERS_RESP,

//IOCTRL_TYPE_SET_GPS_OBD_SEND_PARAMETERS_REQ,
//IOCTRL_TYPE_SET_GPS_OBD_SEND_PARAMETERS_RESP,

typedef struct _GET_GPS_OBD_SEND_PARAMETERS_REQ
{		
	UINT8    u8Reserved[8];	
}RJONE_GET_GPS_OBD_SEND_PARAMETERS_REQ;


typedef struct _GET_GPS_OBD_SEND_PARAMETERS_RESP
{
	INT32 	s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	UINT32	u32EnalbeAutoSendGPSOBDData;     //�Ƿ��Զ�����GPS + OBD ��Ϣ  0 ������  1 ����
	UINT8    u8Reserved[8];	
}RJONE_GET_GPS_OBD_SEND_PARAMETERS_RESP;


typedef struct _SET_GPS_OBD_SEND_PARAMETERS_REQ
{		
	UINT32	u32EnalbeAutoSendGPSOBDData;     //�Ƿ��Զ�����GPS + OBD ��Ϣ  0 ������  1 ����
	UINT8    u8Reserved[8];
}RJONE_SET_GPS_OBD_SEND_PARAMETERS_REQ;


typedef struct _SET_GPS_OBD_SEND_PARAMETERS_RESP
{
	INT32 	s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��		
	UINT8      u8Reserved[8];
}RJONE_SET_GPS_OBD_SEND_PARAMETERS_RESP;


//�ϴ�GPS OBD ʵʱ���� mac -> app  ����Ҫ�ظ�
//IOCTRL_TYPE_SEND_GPS_OBD_REQ,
//IOCTRL_TYPE_SEND_GPS_OBD_RESP,
typedef struct _GET_SEND_GPS_OBD_REQ
{		
	RJONE_DC_EXTERNAL_DATA_INFO stDataInfo;	//�ⲿ����
	UINT8    u8Reserved[8];	
}RJONE_SEND_GPS_OBD_REQ;




//�õ�����������ݵİ汾��
//IOCTRL_TYPE_GET_DEV_ALL_APPVER_REQ,	
//IOCTRL_TYPE_GET_DEV_ALL_APPVER_RESP,
typedef struct _GET_DEV_ALL_APPVER_REQ
{			
	UINT8 u8Reserved[8];	
}RJONE_GET_DEV_ALL_APPVER_REQ;

typedef struct _GET_DEV_ALL_APPVER_RESP
{	
	INT32  s32Result;			//RJONE_SUCCESS �ɹ�:   ʧ�ܷ��ش���ԭ��	
	UINT8  u8SoftVer[64];			//����汾��
	UINT8  u8SoundDataVer[32];		//��Ƶ���ݰ汾��
	UINT8  u8Reserved[96];
}RJONE_GET_DEV_ALL_APPVER_RESP;


//֪ͨAPP  �Ƿ����˾��� ��չ�Ṧ��(�豸�������͸�APP��APP����ҪӦ��)
//IOCTRL_TYPE_SEND_PIR_INFO_REQ,	
//IOCTRL_TYPE_SEND_PIR_INFO_RESP,
typedef struct _SEND_PIR_INFO_REQ
{		
	UINT8 u8CheckPeople;     //u8CheckPeople = 1 ��ʾ����, u8CheckPeople = 0 ��ʾ����, 
	UINT8  u8Reserved[31];
}RJONE_SEND_PIR_INFO_REQ;
	

//////////////////////////////////////////////////////////////////////////////////////////////////



/******************************************************************************************
							���������豸�㲥���
*******************************************************************************************/

////////������ݽṹ////////

#define RJONE_REQUEST_DEV_INFO   5

#define RJONE_BROADCAST_RECV_PORT (22356)


typedef struct _DEV_NET_INFO
{
	    UINT32 u32ListenPort;			// �豸�����˿�
           CHAR u8IP[16];				//�豸IP 
           CHAR u8MAC[18];	   			// �豸 MAC 
	     UINT8 u8Reserved[2];		   
}RJONE_DEV_NET_INFO;

typedef struct  _DEV_BROADCAST_
{
        CHAR strDevId[64];         //�豸ΨһID   ,                                           
        RJONE_DEV_NET_INFO   apInfo;   //����AP ģʽ��������Ϣ
	 RJONE_DEV_NET_INFO   staInfo;  // ����STA ģʽ.  ������Ϣ
	 RJONE_DEV_NET_INFO   lineInfo;  //����ģʽ��������Ϣ
	 UINT32 u32SoftwareV;  //����汾
	 UINT32 u32FirewareV;  //Ӳ���汾
	 UINT8 u8DevType;          // �豸����
	 UINT8 u8Cmd;                 // �豸�˷��Ͳ�ѯ��Ϣʱ����RJONE_REQUEST_DEV_INFO ֵ��
        UINT8 u8Reserved[6];
}RJONE_DEV_SEND_BROADCAST,RJONE_DEV_RECV_BROADCAST;


///////////////////////////////////////////////////////////////////////////////////////////



/******************************************************************************************
								������
*******************************************************************************************/

////////������ݽṹ////////


typedef enum {
	SIO_TYPE_UNKN,
	SIO_TYPE_VIDEO_AUDIO_FRAME,	
	SIO_TYPE_IOCTRL,
	SIO_TYPE_DOWNLOAD_DATA,
	SIO_TYPE_HEART_ALIVE_PACKET,
	SIO_TYPE_UPGRADE_PACKET,
}RJONE_STREAM_IO_TYPE;

//NOTE: struct below is all Little Endian
typedef struct
{
        UINT8 u8StreamIOType; 			//��д RJONE_STREAM_IO_TYPE  �������
        UINT8  u8Reserved[3];
        UINT32 u32DataSize;	                    //�������ݰ�����
}RJONE_STREAM_IO_HEAD;



//for SIO_TYPE_IOCTRL
typedef struct{
	UINT16 u16IOCtrlType;					//�ο� RJONE_IOCTRL_TYPE
	UINT16 u16IOCtrlDataSize;
	UINT8   u8Reserve[4];
}RJONE_IO_CTRL_HEAD;

typedef struct _VIDEO_FRAME_HEADER_
{	
	UINT32 nTimeStampSec;				// ʱ�����
	UINT32 nTimeStampUSec;				// ʱ���΢��
	UINT32 u32FrameDataLen;			       // ֡���ݳ���
	UINT8   u8Code;						//ѹ����ʽ RJONE_CODE_TYPE
	UINT8   u8VideoFrameType;			// I֡ or  p֡or b֡  RJONE_VIDEO_FRAME
	UINT8   u8FrameIndex;			//֡����������I֡ʱ��u8rameIndex = 0��p֡ʱu8rameIndex=u8rameIndex+1. ���������Ҫ�����ж϶�֡�����
	UINT8   u8Reserved2;
	UINT16 u16PicWidth;				//ͼ��Ŀ�
	UINT16 u16PicHeight;				//ͼ��ĸ�
	UINT8   u8Reserved[4];
}RJONE_VIDEO_FRAME_HEADER;

typedef struct _AUDIO_FRAME_HEADER_
{
	UINT8 u8Code;							//ѹ����ʽRJONE_CODE_TYPE
	UINT8 u8AudioSamplerate;				//������ RJONE_AUDIO_SAMPLERATE
	UINT8 u8AudioBits;						//����λ��RJONE_AUDIO_DATABITS
	UINT8 u8AudioChannel;					//ͨ��		RJONE_AUDIO_CHANNEL					
	UINT32 nTimeStampSec;				// ʱ��� ΢����	
	UINT32 nTimeStampUSec;				// ʱ���΢��
	UINT32 u32FrameDataLen;			// ֡���ݳ���	
	UINT8   u8FrameIndex;			//֡������ÿ��һ֡ u8rameIndex=u8rameIndex+1. ���������Ҫ�����ж϶�֡�����
	UINT8   u8Reserved[7];
}RJONE_AUDIO_FRAME_HEADER;


// for SIO_TYPE_VIDEO_AUDIO_FRAME
typedef struct _FRAME_HEAD_
{	
	UINT8 u8FrameType;  				       // �ο� RJONE_FRAME_TYPE
	UINT8 u8FrameUseType;				// �ο� FRAME_USE_TYPE	
	UINT16 u16FrameSplitPackTotalNum;	       // ��֡���ݴ�С�������ͻ���ʱ�����зְ���u8FramePackNum��ʾ�ְ����ܸ�����С�ڵ���1  ʱ����ʾδ�ְ���
	UINT16 u16SplitPackNo;					// ��ǰ�ְ������		
	UINT16 u16SessionId;
	union
	{
		RJONE_VIDEO_FRAME_HEADER stVideoFrameHead; 
		RJONE_AUDIO_FRAME_HEADER stAudioFrameHead;
	};		
}RJONE_FRAME_HEAD;



// for SIO_TYPE_SEND_FILE_DATA
typedef struct _FILE_DOWNLOAD_PACK_HEAD_
{	
	UINT32  u32FileTotalSize;			//�����ļ����ܳ���
	UINT32  u32TotalSendPackNum;	//Ҫ���͵��ܰ���
	UINT32  u32CurPackNo;			//��ǰ�������
	UINT32  u32CurPackSize;			//��ǰ����¼���ļ�����
	UINT32  uCRC;					// uCRC=0 ʱ��Ч��
	UINT8    u8Endflag;				//u8Endflag=1: ��ʾ��ǰ���ǽ�����	
	UINT8    u8Reserve[3];	
	UINT16  u16SessionId;				// ����ID
	UINT8    u8Reserve2[2];	
	UINT8    u8Data[0];				//���ݵ���ʼ��ַ	
}RJONE_FILE_DOWNLOAD_PACK_HEAD;




// ��������͸�ʽ

/*   �������ݰ�

	RJONE_STREAM_IO_HEAD + RJONE_IO_CTRL_HEAD + ��������

*/


/*  ����Ƶ���ݰ�

	RJONE_STREAM_IO_HEAD + RJONE_FRAME_HEAD + ����Ƶ����

*/

/* �����ļ����ݰ�

	RJONE_STREAM_IO_HEAD + RJONE_FILE_DOWNLOAD_PACK_HEAD + ��Ƶ�ļ�����

*/


/* �����ļ����ݰ�

	RJONE_STREAM_IO_HEAD + RJONE_UPGRADE_HEAD + �����ļ�����

*/

/*  ����������
	RJONE_STREAM_IO_HEAD     u8StreamIOType=SIO_TYPE_HEART_ALIVE_PACKET
*/

////////////////////////////////////////////////////////////////////////////////////////////////////


#ifdef __cplusplus
}
#endif

#endif 
