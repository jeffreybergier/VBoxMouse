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
*	Category of EventSrcPCPointer to support posting of absolute          *
*	pointer events received from VMMouse to the event driver.             *
*	                                                                      *
\*---------------------------------------------------------------------------*/
#import <driverkit/generalFuncs.h>
#import <driverkit/eventProtocols.h>
#import <bsd/dev/evsio.h>
#import <bsd/dev/ev_types.h>

#import "VMMousePointer.h"
#import "vmmouse_defs.h"

@implementation EventSrcPCPointer(VMMousePointer)
/*--------------------------- processVMMouseInput: --------------------------*\
*									      *
*	Handle input coming from VMMouse and dispatch it to the               *
*	EventDriver                                                           *
*									      *
\*---------------------------------------------------------------------------*/

- processVMMouseInput:(PVMMOUSE_INPUT_DATA)input
{
    int		buttons;
    Point	position;
    
    [deviceLock lock];
    
				/* Process mouse buttons                     */
    buttons = 0;
    if (input->Buttons & VMMOUSE_LEFT_BUTTON)
	buttons |= EV_LB;
    if (input->Buttons & VMMOUSE_RIGHT_BUTTON)
	buttons |= EV_RB;
    if (input->Buttons & VMMOUSE_MIDDLE_BUTTON)
	buttons |= (EV_LB | EV_RB);
    
				/* Perform button tying and mapping.  This
				   stuff applies to relative posn devices
				   (mice) only.                              */
    if (buttonMode == NX_OneButton)
    {
	if ((buttons & (EV_LB|EV_RB)) != 0)
	    buttons = EV_LB;
    }
				/* Menus on left button. Swap!               */
    else if (buttonMode == NX_LeftButton)
    {
	int	temp=0;
	
	if (buttons & EV_LB)
	    temp = EV_RB;
	if (buttons & EV_RB)
	    temp |= EV_LB;
	buttons = temp;
    }
    
    position.x = input->X;
    position.y = input->Y;
    
    [deviceLock unlock];
    
    [[self owner] absolutePointerEvent:buttons at:&position inProximity:YES];
    
    return self;
} /* processVMMouseInput: */



@end
