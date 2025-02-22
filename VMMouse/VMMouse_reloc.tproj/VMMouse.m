/*---------------------------------------------------------------------------*\
*	                                                                      *
*	Copyright (c) 2006 by Jens Heise                                      *
*	                                                                      *
*	created: 03/11/2006	              last change: 03/13/2006         *
*									      *
*			Version: 1.1					      *
*	                                                                      *
*-----------------------------------------------------------------------------*
*	                                                                      *
*	Hardware interface of the driver. Implements the handling of the      *
*	virtual mouse via the VMware backdoor. Further implements basic       *
*	PS2 mouse handling as the interrupts are received via the PS2         *
*	port and we have to clear the PS2 mouse data although we did not      *
*	use it.                                                               *
*	                                                                      *
\*---------------------------------------------------------------------------*/
#import <driverkit/generalFuncs.h>
#import <driverkit/interruptMsg.h>
#import <driverkit/kernelDriver.h>
#import <kernserv/clock_timer.h>
#import <kernserv/i386/spl.h>
#import <kernserv/prototypes.h>
#import <PS2Controller.h>
#import <PS2Proto.h>

#import "VMMouse.h"
#import "VMMouseConfig.h"
#import "VMMousePointer.h"
#import "vmmouse_client.h"

#define VMMOUSE_NAME	"VMMouse"

static t_ps2_funcs	*ps2Funcs=NULL;
static ns_time_t	lastTime;
static int		indexInSequence;
static BOOL		seqBeingProcessed;

@implementation VMMouse
/*------------------------------- ()mouseInit: ------------------------------*\
*									      *
*	Initializes the mouse. Is called by PCPointer during                  *
*	initFromDeviceDescription:                                            *
*									      *
\*---------------------------------------------------------------------------*/

- (BOOL)mouseInit:deviceDescription
{
    IOReturn	rtn;
    id		ps2Ctrl=nil;
    
				/* Try to enable the vmmouse                 */
    if (!VMMouseClient_Enable())
    {
	IOLog(VMMOUSE_NAME" cannot detect vmmouse\n");
	return NO;
    } /* if */
    else VMMouseClient_Disable();

    absoluteMode = YES;
    force_detection = YES;

    indexInSequence = 0;
    seqBeingProcessed = NO;
    
				/* Get hands on the PS2 controller provided
				   by the PS2 keyboard driver.               */
    rtn = IOGetObjectForDeviceName("PS2Controller", &ps2Ctrl);
    
    if (rtn != IO_R_SUCCESS)
    {
	IOLog(VMMOUSE_NAME" mouseInit: Can't find PS2Controller (%s)\n", 
			[self stringFromReturn:rtn]);
	return NO;
    } /* if */
    
    if (deviceLock == nil)
	deviceLock = [NXLock new];
    
				/* Read our configuration.                   */
    [self readConfigTable:[deviceDescription configTable]];
    
    return [self initWithController:ps2Ctrl];
} /* ()mouseInit: */



/*----------------------------------- free ----------------------------------*\
*									      *
*	«Text»
*									      *
\*---------------------------------------------------------------------------*/

- free
{
    id		lock;

    [deviceLock lock];
    lock = deviceLock;
    deviceLock = nil;

    if (vmmouseInitialized)
	VMMouseClient_Disable();

    [lock unlock];
    [lock free];
	
    return [super free];
} /* free */



/*-------------------------- ()initWithController: --------------------------*\
*									      *
*	Initialize the PS2 part of the driver and switch on the absolute      *
*	mode of the vmmouse interface when successful.                        *
*									      *
\*---------------------------------------------------------------------------*/

- (BOOL)initWithController:aPS2Controller
{
    char	data;
    BOOL	success=YES;
    
				/* We need the controller to enable mouse
				   interrupts.                               */
    if (!aPS2Controller)
    {
	IOLog(VMMOUSE_NAME": no PS2Controller present\n");
	return NO;
    } /* if */
    
				/* Get access functions for the ps2 port from
				   controller                                */
    controller = aPS2Controller;
    ps2Funcs = [controller controllerAccessFunctions];
    [controller setManualDataHandling:YES];
    ps2Funcs->_clearOutputBuffer();
    
				/* Try to find a mouse.                      */
    if (force_detection || [self isMousePresent])
    {
	ps2Funcs->_sendControllerCommand(KC_CMD_READ);
	data = ps2Funcs->_getKeyboardData();
	
				/* Enable the mouse and initialize the PS2
				   part                                      */
	data &= ~M_CB_DISBLE;
	data |= M_CB_ENBLIRQ;
	
	ps2Funcs->_sendControllerCommand(KC_CMD_WRITE);
	ps2Funcs->_sendControllerData(data);
	[self resetMouse];
	
				/* Activate vmmouse and absolute mode        */
	if (absoluteMode && !VMMouseClient_Enable())
	{
	    IOLog(VMMOUSE_NAME" failed to enable vmmouse\n");
	    success = NO;
	}
	else if (absoluteMode)
	{
	    VMMouseClient_RequestAbsolute();
	    vmmouseInitialized = YES;
	} /* if..else if */

				/* Attach to the ps2Controller and start our
				   IOThread                                  */
	if (success)
	{
	    [controller setMouseObject:self];
	    [self setName:VMMOUSE_NAME];
	    [self setDeviceKind:VMMOUSE_NAME];
	    
	    [self enableAllInterrupts];
	    [self startIOThreadWithFixedPriority:28];
	} /* if */
    } /* if */
    else 
    {
	success = NO;
	IOLog(VMMOUSE_NAME": couldn't find a mouse!\n");
    } /* if..else */
    
    [controller setManualDataHandling:NO];

    return success;
} /* ()initWithController: */



/*---------------------------- ()readConfigTable: ---------------------------*\
*									      *
*	Reads the configuration of this driver consiting of the offset        *
*	and size of the desktop the mouse will be used on.                    *
*									      *
\*---------------------------------------------------------------------------*/

- (BOOL)readConfigTable:configTable
{
    BOOL	success=YES;
    char	*value=NULL;
    
    if (!configTable)
	return NO;
    
    [deviceLock lock];
    if ((value = (char*)[configTable valueForStringKey:VMM_XOFFSET]) != NULL)
    {
	desktopBounds.x = PCPatoi(value);
	[configTable freeString:value];
    }
    else desktopBounds.x = VMM_DEF_XOFFSET;
    
    if ((value = (char*)[configTable valueForStringKey:VMM_YOFFSET]) != NULL)
    {
	desktopBounds.y = PCPatoi(value);
	[configTable freeString:value];
    }
    else desktopBounds.y = VMM_DEF_YOFFSET;
    
    if ((value = (char*)[configTable valueForStringKey:VMM_XSIZE]) != NULL)
    {
	desktopBounds.width= PCPatoi(value);
	[configTable freeString:value];
    }
    else desktopBounds.width = VMM_DEF_XSIZE;
	
    if ((value = (char*)[configTable valueForStringKey:VMM_YSIZE]) != NULL)
    {
	desktopBounds.height = PCPatoi(value);
	[configTable freeString:value];
    }
    else desktopBounds.height = VMM_DEF_YSIZE;
    [deviceLock unlock];
    
    return success;
} /* ()readConfigTable: */



/*----------------------------- ()isMousePresent ----------------------------*\
*									      *
*	Tests whether a PS2 mouse is attached. WIthout a PS2 mouse there      *
*	is also no vmmouse.                                                   *
*									      *
\*---------------------------------------------------------------------------*/

- (BOOL)isMousePresent
{
    char	data;
    
    ps2Funcs->_sendMouseCommand(M_CMD_SETRES);
    ps2Funcs->_sendMouseCommand(0x03);
    ps2Funcs->_sendMouseCommand(M_CMD_GETSTAT);
    
    ps2Funcs->_getMouseData();
    data = ps2Funcs->_getMouseData();
    ps2Funcs->_getMouseData();
    
    return (data == 0x03);
} /* ()isMousePresent */



/*------------------------------- ()resetMouse ------------------------------*\
*									      *
*	Reset the mouse port                                                  *
*									      *
\*---------------------------------------------------------------------------*/

- (void)resetMouse
{
    ps2Funcs->_sendMouseCommand(M_CMD_SETDEF);
    ps2Funcs->_sendMouseCommand(M_CMD_POLL);
    
    return;
} /* ()resetMouse */



/*---------------------------- MouseIntHandler() ----------------------------*\
*									      *
*	Handle the ps2 interrupt                                              *
*									      *
\*---------------------------------------------------------------------------*/

static void MouseIntHandler(void *identity, void *state, unsigned int arg)
{
    unsigned char	data;
    ns_time_t		timeStamp;
    
				/* Basic handling of PS2 port to get rid of
				   the mouse data                            */
    if (!ps2Funcs->_getMouseDataIfPresent(&data))
	return;
	
    if (data == 0xaa && indexInSequence == 0)
    {
	IOLog(VMMOUSE_NAME": mouse reset");
	ps2Funcs->_getMouseData();
	ps2Funcs->_sendMouseCommand(M_CMD_POLL);
	
	return;
    }
    else
    {
	IOGetTimestamp(&timeStamp);
	
	if (indexInSequence != 0 && timeStamp - lastTime > (25*1000*1000))
	{
	    indexInSequence = 0;
	    IOLog(VMMOUSE_NAME": mouse reset after resync");
	    ps2Funcs->_getMouseData();
	    ps2Funcs->_sendMouseCommand(M_CMD_POLL);
	    
	    return;
	}
    }
    
    lastTime = timeStamp;
    
    IOSendInterrupt(identity, state, IO_DEVICE_INTERRUPT_MSG);

    seqBeingProcessed = YES;
    indexInSequence = 0;

    return;
} /* MouseIntHandler() */



/*--------------------------- ()interruptOccurred ---------------------------*\
*									      *
*	Process the data available from the vm port                           *
*									      *
\*---------------------------------------------------------------------------*/

- (void)interruptOccurred
{
				/* Get all queued mouse events from the VM
				   and hand them to our own event source     */
    if (absoluteMode && target)
    {
	VMMOUSE_INPUT_DATA	vmmouseInput;
	
	while (VMMouseClient_GetInput(&vmmouseInput))
	{
	    [deviceLock lock];
				/* Scale and offset the coords to our desktop*/
	    vmmouseInput.X = (vmmouseInput.X * desktopBounds.width / 65535) 
	   			+ desktopBounds.x;
	    vmmouseInput.Y = (vmmouseInput.Y * desktopBounds.height / 65535) 
	    			+ desktopBounds.y;
	    [deviceLock unlock];

	    [target processVMMouseInput:&vmmouseInput];
	} /* while */
    } /* if */
    
    seqBeingProcessed = NO;
    
    return;
} /* ()interruptOccurred */



/*---------------- ()getHandler:level:argument:forInterrupt: ----------------*\
*									      *
*	Replace the interrupt handler with our own version                    *
*									      *
\*---------------------------------------------------------------------------*/

- (BOOL)getHandler:(IOInterruptHandler *)handler level:(unsigned int *)ipl argument:(unsigned int *)arg forInterrupt:(unsigned int)localInterrupt
{
    *handler = MouseIntHandler;
    *ipl = IPLDEVICE;
    *arg = absoluteMode;
    
    return YES;
} /* ()getHandler:level:argument:forInterrupt: */


/*----------------------------- ()getResolution -----------------------------*\
*									      *
*	Since this is an absolute pointing device there is no resolution.     *
*									      *
\*---------------------------------------------------------------------------*/

- (int)getResolution
{
    return 0;
} /* ()getResolution */



/*-------------------- ()getIntValues:forParameter:count: -------------------*\
*									      *
*	Method for getting the driver settings.                               *
*									      *
\*---------------------------------------------------------------------------*/

- (IOReturn)getIntValues:(unsigned *)parameterArray forParameter:(IOParameterName)parameterName count:(unsigned int *)count
{
    IOReturn	r=IO_R_INVALID_ARG;
    unsigned	maxCount=*count;
    unsigned	*returnedCount=count;
    
				/* Desktop geometry                          */
    if (strcmp(parameterName, VMM_GEOMETRY) == 0 && maxCount >= 4)
    {
	*returnedCount = 4;
	[deviceLock lock];
	parameterArray[0] = desktopBounds.x;
	parameterArray[1] = desktopBounds.y;
	parameterArray[2] = desktopBounds.width;
	parameterArray[3] = desktopBounds.height;
	[deviceLock unlock];
	r = IO_R_SUCCESS;
    }
    else
    {
	r = [super getIntValues:parameterArray 
			forParameter: parameterName count: count];
	if (r == IO_R_UNSUPPORTED)
	    r = IO_R_INVALID_ARG;
    }
    return r;
} /* ()getIntValues:forParameter:count: */



/*-------------------- ()setIntValues:forParameter:count: -------------------*\
*									      *
*	Method for setting the driver settings.                               *
*									      *
\*---------------------------------------------------------------------------*/

- (IOReturn)setIntValues:(unsigned *)parameterArray forParameter:(IOParameterName)parameterName count:(unsigned int)count
{
    IOReturn	r=IO_R_INVALID_ARG;

				/* Desktop geometry                          */
    if (strcmp(parameterName, VMM_GEOMETRY) == 0 && count == 4)
    {
	[deviceLock lock];
	desktopBounds.x = parameterArray[0];
	desktopBounds.y = parameterArray[1];
	desktopBounds.width = parameterArray[2];
	desktopBounds.height = parameterArray[3];
	[deviceLock unlock];
	r = IO_R_SUCCESS;
    }
    else
    {
	r = [super setIntValues:parameterArray
			forParameter:parameterName count: count];
	if (r == IO_R_UNSUPPORTED)
	    r = IO_R_INVALID_ARG;
    }
    return r;
} /* ()setIntValues:forParameter:count: */



@end
