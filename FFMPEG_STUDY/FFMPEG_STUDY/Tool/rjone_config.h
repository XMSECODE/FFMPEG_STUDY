#ifndef _RJONE_CONFIG_H_
#define _RJONE_CONFIG_H_

#ifdef __cplusplus
extern "C" {
#endif


#define USE_NET_P2P_1

//#define USE_NET_P2P_2

//#define USE_NET_P2P_3


//#define USE_RTSP

#define NETWORK_WIFI

#define USE_SELF_BUFFER





//�Ƿ�ʹ��¼��ģ��
#define USE_RECORD_MODULE

//������Ƶ
#define USE_DEV_AUDIO


//�����Ƿ����������
#define SEND_NET_ALIVE_PACKET 



//ʹ��summer ����i2c
//#define ADD_SUMMER_DEV_CTRL


//ʹ���������
#define USE_NET_DEBUG


//h264���ݼ���
//#define H264_USE_AES_ENCRYPTTION


//��˼����I2C ���sensor ����
#define USE_HISI_I2C_CHECK_SENSOR


//��ʱץ������ͼ
#define USE_FIX_TIME_GET_PIC

//ץͼ�����mediaId
#define HIGH_QUALITY_SNAP_PICTURE_MEDIAID (3)
#define LOW_QUALITY_SNAP_PICTURE_MEDIAID (4)

//��ͼ�����ץͼǰ���5��һ��ʮ���¼���ļ�
#define CREATE_SNAP_VIDEO_RECORD  

//ʹ�ô���
#define USE_UART


#define SYSTEM_MTD_FILE       "/dev/mtdblock4"
#define SYSTEM_NEW_MTD_FILE       "/dev/mtdblock5"


#define SD_MIN_SIZE_M			(200)    //����ʣ���ռ�ʱ���Ϳ�ʼѭ�������ļ�

#define SD_CARD_MOUNT_PATH   	 "/mnt/storage"
#define NORMAL_VIDEO_PATH		 "/mnt/storage/video"
#define SNAP_WRITE_PATH		 	 "/mnt/storage/snap"
#define SNAP_PIC_PATH		 	 "/mnt/storage/snap/pic"
#define SNAP_VIDEO_PATH		 	 "/mnt/storage/snap/video"
#define EMERGENCY_RECORD_PATH	 "/mnt/storage/alarm"
#define MEDIA_LOST_PATH		 	 "/mnt/storage/video/lost+file"
#define TMP_SNAP_WRITE_PATH	 "/tmp/snap"
#define TMP_GPS_WRITE_PATH		 "/tmp/gps"
#define TMP_TF_UPDATE_WRITE_PATH		 "/mnt/storage/update/"


#define USE_DISK_SPACE_CTRL_THREAD
#define RECORD_DISK_SPACE_PERCENT  800/1000
#define SNAP_DISK_SPACE_PERCENT  100/1000
#define EMERGENCY_RECORD_DISK_SPACE_PERCENT  100/1000


//ʹ��������ʾ 
#define USE_VOICE_PROMPT

//#define HISI_3518E_FRAMERATE_CTRL


//������ʱ��¼����
#define CREATE_TMP_ACCESS_PASSWORD


//���籨����
#define USE_ALARM_VOICE

#define  ALARM_FILE_RAMDISK_PATH  "/usr/changhong_voice/"
#define  ALARM_FILE_PATH  "/mnt/storage/alarm_voice/"
#define  ALARM_START_UP   					ALARM_FILE_PATH"14.pcm"
#define  ALARM_SHUT_DOWN   				ALARM_FILE_PATH"15.pcm"
#define  ALARM_MOBILE_CONNECTED			ALARM_FILE_PATH"16.pcm"
#define  ALARM_MOBILE_DISCONNECT   		ALARM_FILE_PATH"17.pcm"
#define  ALARM_ENMERGENCY_VIDEO_LOCK   	ALARM_FILE_PATH"18.pcm"
#define  ALARM_PARK_START   				ALARM_FILE_PATH"19.pcm"
#define  ALARM_NORMAL_DRIVER_START   		ALARM_FILE_PATH"20.pcm"
#define  ALARM_MACHINE_RESET   				ALARM_FILE_PATH"21.pcm"

#define  ALARM_SNAP   						ALARM_FILE_PATH"100.pcm"


#define  ALARM_TFCARD_UNUSUAL   			ALARM_FILE_PATH"4.pcm"
#define  ALARM_WIFI_UNUSUAL   				ALARM_FILE_PATH"22.pcm"
#define  ALARM_GPS_UNUSUAL   				ALARM_FILE_PATH"23.pcm"
#define  ALARM_ODB_UNUSUAL   				ALARM_FILE_PATH"24.pcm"

#define  ALARM_CAR_BATTERY_LOW_12V   							ALARM_FILE_PATH"25.pcm"
#define  ALARM_CAR_ENGINE_COOLING_FLUILD_MORE_100C   		ALARM_FILE_PATH"26.pcm"
#define  ALARM_CAR_ENGINE_LOAD_TOO_HIGH  		      			ALARM_FILE_PATH"27.pcm"
#define  ALARM_CAR_REMNANT_GAS_LOW_10PRECENT				ALARM_FILE_PATH"28.pcm"
#define  ALARM_CAR_FAST_SPPD_MORE_120KM						ALARM_FILE_PATH"29.pcm"
#define  ALARM_CAR_TIREDNESS_DRIVER_MORE_3HOURS			ALARM_FILE_PATH"30.pcm"
#define  ALARM_CAR_CHARGE_ISSUE								ALARM_FILE_PATH"31.pcm"
#define  ALARM_CAR_ENGINE_ISSUE								ALARM_FILE_PATH"32.pcm"
#define  ALARM_CAR_ENGINE_COOLING_TOO_LOW                              ALARM_FILE_PATH"33.pcm"
#define  ALARM_CAR_ENGINE_COOLING_TOO_HIGH                             ALARM_FILE_PATH"34.pcm"
#define  ALARM_CAR_MAINTAIN_NOTICE						      ALARM_FILE_PATH"35.pcm"


//SONSER ѡ����оƬѡ��
#define NOT_USE_SENSOR_AUTO_CHECK 

//�ڱ���ѡ����ȷ��������оƬ
//#define USE_HI3516A_CHIP
//#define USE_HI3516D_CHIP

#ifdef USE_HI3516A_CHIP
#define USE_SENSOR_IMX178
#define NEW_APP_VERSON  "A110-HW02HS-RJone-1.0.5.20160112"
//#define USE_DM2016_ENCRYPTION
#endif


#ifdef USE_HI3516D_CHIP
#define USE_SENSOR_NM34220
#define NEW_APP_VERSON  "A110-HW03HS-RJone-1.0.28.20160219"

#define USE_DM2016_ENCRYPTION
#define USE_GSENSOR			//ʹ��GSensor

//ʹ�ó�������
#define CHECK_POWER_USE_SUPER_ELECTRIC_CAPACITY 

//ʹ��ң����
#define USE_REMOTE_CONTROL

//��������
#define USE_BUTTON_CONTROL

//ʹ��GPS&OBD	
#define USE_GPS_OBD


//ʹ��ת����
#define USE_STEERING_MOTOR

//����ͣ�����
//#define TEST_PARK_RECORD

//�����Լ쿪��
#define AUTO_CHECK_MACHINE


//չ�Ṧ��
//#define USE_EXHIBITION_FUNC



#endif

//��Ƶ���ݰ汾�ļ�
#define AUDIO_DATA_VER_CFG  	ALARM_FILE_PATH"audio_ver.cfg"


//ʹ��RTC����¼ʱ��
#define USE_RTC_TIME


//RTC ������־
//#define USE_TEST_RTC_LOG


#define DEBUG_LOG_FILE "/mnt/mtd/debug.log"


//ʹ��������λ
#define USE_SOUND_POSITION

//WIFI STATION ģʽ�£��Զ����㲥
#define SEND_BROADCAST_WIFI_STA


//ʹ�ö��߳�����
#define USE_MULT_THREAD_DOWNLOAD


//�򿪰����ҹ& ����������
#define USE_ISP_ENVIRONMENT_CHECK 





#ifdef __cplusplus
}
#endif

#endif 

