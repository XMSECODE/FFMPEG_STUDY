#ifndef _RJONE_TYPE_H_
#define _RJONE_TYPE_H_

#ifdef __cplusplus
extern "C" {
#endif

#include <string.h>
#include <stdlib.h>
#include <stdio.h>



typedef char				CHAR;
typedef char				INT8;
typedef short				INT16;
typedef int				INT32;
typedef unsigned char		UINT8;
typedef unsigned short		UINT16;
typedef unsigned int		UINT32;
typedef unsigned long long		UINT64;

typedef void *			HANDLE;
typedef void				VOID;



#ifndef J_OUT
#define J_OUT
#endif

#ifndef J_IN
#define J_IN
#endif


#ifdef __cplusplus
}
#endif

#endif 

