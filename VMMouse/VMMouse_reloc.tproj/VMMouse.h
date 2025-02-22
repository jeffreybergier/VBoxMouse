/*---------------------------------------------------------------------------*\
*	                                                                      *
*	Copyright (c) 2006 by Jens Heise                                      *
*	                                                                      *
*	created: 03/11/2006	              last change: 03/13/2006         *
*									      *
*			Version: 1.1					      *
*	                                                                      *
\*---------------------------------------------------------------------------*/
#define DRIVER_PRIVATE 1
#import "PCPointer.h"
#undef DRIVER_PRIVATE

@interface VMMouse : PCPointer
{
    id		controller;	/* The PS2 controller we use		     */
    
    BOOL	absoluteMode;
    BOOL	vmmouseInitialized;
    BOOL	force_detection;
    
    @private
    id		deviceLock;
    struct {
	short	x;
	short	y;
	short	width;
	short	height;
    } desktopBounds;		/* Desktop geometry the mouse uses	     */
}

- (BOOL)mouseInit:deviceDescription;
- free;

- (BOOL)initWithController:aPS2Controller;
- (BOOL)readConfigTable:configTable;

- (BOOL)isMousePresent;
- (void)resetMouse;

- (void)interruptOccurred;
- (BOOL)getHandler:(IOInterruptHandler *)handler level:(unsigned int *)ipl argument:(unsigned int *)arg forInterrupt:(unsigned int)localInterrupt;

- (int)getResolution;

- (IOReturn)getIntValues:(unsigned *)parameterArray forParameter:(IOParameterName)parameterName count:(unsigned int *)count;
- (IOReturn)setIntValues:(unsigned *)parameterArray forParameter:(IOParameterName)parameterName count:(unsigned int)count;

@end
