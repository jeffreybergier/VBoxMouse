/*---------------------------------------------------------------------------*\
*	                                                                      *
*	Copyright (c) 2006 by Jens Heise                                      *
*	                                                                      *
*	created: 03/11/2006	              last change: 03/13/2006         *
*									      *
*			Version: 1.1					      *
*	                                                                      *
\*---------------------------------------------------------------------------*/
#define	DRIVER_PRIVATE
#import "EventSrcPCPointer.h"
#undef DRIVER_PRIVATE

#import "vmmouse_client.h"

@interface EventSrcPCPointer(VMMousePointer)
- processVMMouseInput:(PVMMOUSE_INPUT_DATA)input;
@end
