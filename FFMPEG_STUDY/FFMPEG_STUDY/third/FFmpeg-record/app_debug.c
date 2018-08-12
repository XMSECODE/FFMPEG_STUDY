#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#include <stdio.h>
#include <pthread.h>
#include  <string.h>
#include <signal.h>
#include <fcntl.h>
#include <unistd.h>


#include "rjone_debug.h"
#include "app_debug.h"

//#define USE_MEM_DEBUG 

static int iTotalMallocSize = 0;
static int iAddrNum = 0;
pthread_mutex_t stMemLock;
static int iMallocInit = 0;

MEM_DEBUG_ST stMemItemList[MAX_DEBUG_MEM_ITEM_LIST];


void * Debug_Malloc(int iSize)
{
	void * pAddr = NULL;
	int i = 0;

	#ifdef USE_MEM_DEBUG

	if( iMallocInit == 0)
	{
		pthread_mutex_init(&stMemLock,NULL);
		iMallocInit = 1;
		iTotalMallocSize = 0;
	}
	
	pthread_mutex_lock(&stMemLock);
	pAddr = malloc(iSize);
	if( pAddr )
	{
		if( iSize == 8192 )
		{
			DPRINTK("malloc 8192 mem size addr:%x\n",pAddr);			
		}
	
		for( i = 0; i < MAX_DEBUG_MEM_ITEM_LIST; i++)
		{
			if(stMemItemList[i].pAddr == 0 )
			{
				stMemItemList[i].pAddr = pAddr;
				stMemItemList[i].iSize = iSize;
				iTotalMallocSize += iSize;
				iAddrNum++;
				break;
			}
		}

		if( i >= MAX_DEBUG_MEM_ITEM_LIST - 100 )
		{
			DPRINTK("List size not enough\n");
			exit(0);
		}
		
	}
	pthread_mutex_unlock(&stMemLock);
	#else
//    pAddr = malloc(iSize);
	#endif

	return pAddr;
}


void * Debug_Free(void * pAddr)
{
	int i = 0;

	#ifdef USE_MEM_DEBUG
	
	if( iMallocInit == 0)
	{
		pthread_mutex_init(&stMemLock,NULL);
		iMallocInit = 1;
		iTotalMallocSize = 0;
	}
	
	pthread_mutex_lock(&stMemLock);
	free(pAddr);	
	{

	
		
		for( i = 0; i < MAX_DEBUG_MEM_ITEM_LIST; i++)
		{
			if(stMemItemList[i].pAddr == pAddr )
			{
				if( stMemItemList[i].iSize == 8192 )
				{
					DPRINTK("free 8192 mem size  add:%x\n",stMemItemList[i].pAddr);			
				}
				
				iTotalMallocSize -= stMemItemList[i].iSize;
				iAddrNum--;
				stMemItemList[i].pAddr = 0;
				stMemItemList[i].iSize = 0;				
				break;
			}
		}		
	}
	pthread_mutex_unlock(&stMemLock);
	#else
//    free(pAddr);
	#endif

	return 1;
}

int Debug_GetMemSize()
{
	return iTotalMallocSize;
}


int Debug_GetMemAddrNum()
{
	return iAddrNum;
}

void Debug_ShowAllAddr()
{
	int  i = 0;
	#ifdef USE_MEM_DEBUG
	pthread_mutex_lock(&stMemLock);
	{				
		for( i = 0; i < MAX_DEBUG_MEM_ITEM_LIST; i++)
		{
			if(stMemItemList[i].pAddr != 0 )
			{
				DPRINTK("mem addr:[%d] addr:0x%x size:%d\n",i,stMemItemList[i].pAddr,stMemItemList[i].iSize);				
			}
		}		
	}
	pthread_mutex_unlock(&stMemLock);
	#endif
}


