/*---------------------------------------------------------------------------*\
*	                                                                      *
*	Copyright (c) 2006 by Jens Heise                                      *
*	                                                                      *
*	created: 03/11/2006	              last change: 03/11/2006         *
*									      *
*			Version: 1.0					      *
*	                                                                      *
\*---------------------------------------------------------------------------*/

#ifndef _COMPAT_H_
#define _COMPAT_H_

#import <driverkit/generalFuncs.h>

typedef char           Bool;

typedef unsigned int	uint32_t;
typedef unsigned short	uint16_t;

#ifndef FALSE
#define FALSE          0
#endif

#ifndef TRUE
#define TRUE           1
#endif

#ifndef __i386__
#define __i386__
#endif

#ifndef ErrorF
#define ErrorF	IOLog
#endif
#endif