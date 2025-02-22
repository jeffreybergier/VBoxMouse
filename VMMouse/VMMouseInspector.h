/*---------------------------------------------------------------------------*\
*	                                                                      *
*	Copyright (c) 2006 by Jens Heise                                      *
*	                                                                      *
*	created: 03/12/2006	              last change: 03/12/2006         *
*									      *
*			Version: 1.0					      *
*	                                                                      *
\*---------------------------------------------------------------------------*/

#import <driverkit/IODeviceInspector.h>

#define VMM_PARAM_COUNT	4


@interface VMMouseInspector : IODeviceInspector
{
    id		layoutBox;
    id		xField;
    id		yField;
    id		widthField;
    id		heightField;
    
    IODeviceMaster	*deviceMaster;
    IOObjectNumber	deviceTag;
    int		parameterArray[VMM_PARAM_COUNT];
}

- init;
- setTable:(NXStringTable*)instance;

- reloadFields;
- fieldChanged:sender;

@end
