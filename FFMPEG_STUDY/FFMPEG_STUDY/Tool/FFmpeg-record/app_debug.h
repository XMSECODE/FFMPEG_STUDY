#ifndef _COMMON_FUNC_H_
#define _COMMON_FUNC_H_

#ifdef __cplusplus
extern "C" {
#endif

#define MAX_DEBUG_MEM_ITEM_LIST  (1000)

typedef struct _MEM_DEBUG_ST_
{
	void * pAddr;
	int iSize;
}MEM_DEBUG_ST;

#ifdef __cplusplus
}
#endif

#endif 
