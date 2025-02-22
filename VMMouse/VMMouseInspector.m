/*---------------------------------------------------------------------------*\
*	                                                                      *
*	Copyright (c) 2006 by Jens Heise                                      *
*	                                                                      *
*	created: 03/12/2006	              last change: 03/13/2006         *
*									      *
*			Version: 1.1					      *
*	                                                                      *
\*---------------------------------------------------------------------------*/

#import <driverkit/IODeviceMaster.h>
#import <objc/NXBundle.h>

#import "VMMouseInspector.h"
#import "VMMouse_reloc.tproj/VMMouseConfig.h"

#define VMMOUSEI_NAME	"VMMouseInspector"


static const char	*parameterNames[]={
		VMM_XOFFSET, VMM_YOFFSET, 
		VMM_XSIZE, VMM_YSIZE, NULL };


@implementation VMMouseInspector
/*----------------------------------- init ----------------------------------*\
*									      *
*	Initialize Interface                                                  *
*									      *
\*---------------------------------------------------------------------------*/

- init
{
    char	buffer[MAXPATHLEN+1];
    id		bundle=[NXBundle bundleForClass:[self class]];
    IOString	kind;
    IOReturn	ret;
    
    [super init];
    
				/* Find and load the nib file                */
    if (![bundle getPath:buffer forResource:VMMOUSEI_NAME ofType:"nib"])
	return [self free];
    
    if (![NXApp loadNibFile:buffer owner:self withNames:NO])
	return [self free];
    
				/* Configure the fields                      */
    [[xField cell] setEntryType:NX_INTTYPE];
    [[yField cell] setEntryType:NX_INTTYPE];
    [[widthField cell] setEntryType:NX_INTTYPE];
    [[heightField cell] setEntryType:NX_INTTYPE];
    
				/* Connect to the device                     */
    deviceMaster = [IODeviceMaster new];
    ret = [deviceMaster lookUpByDeviceName:VMMOUSE_DEV_NAME 
    				objectNumber:&deviceTag deviceKind:&kind];
    if (ret != IO_R_SUCCESS)
    {
	deviceMaster = nil;
	NXLogError("Couldn't find VMMouse device: error %d\n", ret);
    } /* if */
    
    return self;
} /* init */



/*-------------------------------- setTable: --------------------------------*\
*									      *
*	Set up the connection to our device and the description table         *
*									      *
\*---------------------------------------------------------------------------*/

- setTable:(NXStringTable*)instance
{
    IOReturn	ret=IO_R_INVALID;
    int		count=VMM_PARAM_COUNT;
    
    [super setTable:instance];
    [self setAccessoryView:layoutBox];
    
    if (deviceMaster)
    {
	ret = [deviceMaster getIntValues:parameterArray 
			forParameter:VMM_GEOMETRY 
			objectNumber:deviceTag count:&count];

	if (ret != IO_R_SUCCESS)
	    NXLogError("Couldn't get value for %s", VMM_GEOMETRY);
	else if (count != VMM_PARAM_COUNT)
	{
	    NXLogError("Wrong parameter count for %s. Expected %d, got %d", 
	    			VMM_GEOMETRY, VMM_PARAM_COUNT, count);
	    ret = IO_R_INVALID_ARG;
	} /* if */
    } /* if */
    else
    {
				/* If no deviceMaster is present set defaults*/
	parameterArray[0] = VMM_DEF_XOFFSET;
	parameterArray[1] = VMM_DEF_YOFFSET;
	parameterArray[2] = VMM_DEF_XSIZE;
	parameterArray[3] = VMM_DEF_YSIZE;
    
	ret = IO_R_NO_DEVICE;
    } /* if..else */
    
				/* Load parameters from table if device
				   cannot be found                           */
    if (ret != IO_R_SUCCESS)
    {
	int	i;
	const char	*strValue=NULL;
	
	for (i=0; i<VMM_PARAM_COUNT; i++)
	{
	    if (parameterNames[i] == NULL)
		break;

	    strValue = [instance valueForStringKey:parameterNames[i]];
	    if (strValue == NULL)
		continue;
		
	    parameterArray[i] = atoi(strValue);
	} /* for */
    } /* if */
    
    [self reloadFields];
    
    return self;
} /* setTable: */



/*------------------------------- reloadFields ------------------------------*\
*									      *
*	Update the fields                                                     *
*									      *
\*---------------------------------------------------------------------------*/

- reloadFields
{
    [xField setIntValue:parameterArray[0]];
    [yField setIntValue:parameterArray[1]];
    [widthField setIntValue:parameterArray[2]];
    [heightField setIntValue:parameterArray[3]];
    
    return self;
} /* reloadFields */



/*------------------------------ fieldChanged: ------------------------------*\
*									      *
*	Update the configuration table and our device.                        *
*									      *
\*---------------------------------------------------------------------------*/

- fieldChanged:sender
{
    int		paramTag=[sender tag];
    int		intValue=[sender intValue];
    char	strValue[20];
    IOReturn	rtn;
    
    if (paramTag >= VMM_PARAM_COUNT)
	return nil;
    
    if (intValue > MAXSHORT || intValue < MINSHORT)
    {
	intValue = (intValue > MAXSHORT ? MAXSHORT : MINSHORT);
	[sender setIntValue:intValue];
    } /* if */
    
    sprintf(strValue, "%d", intValue);
    [table insertKey:parameterNames[paramTag] value:(void*)strValue];
    parameterArray[paramTag] = intValue;
    
    if (deviceMaster)
    {
	rtn = [deviceMaster setIntValues:parameterArray 
			forParameter:VMM_GEOMETRY 
			objectNumber:deviceTag count:VMM_PARAM_COUNT];
	if (rtn != IO_R_SUCCESS)
	{
	    NXLogError("Couldn't set values for %s: %d\n", 
	    			VMM_GEOMETRY, rtn);
	} /* if */
    } /* if */
    
    return self;
} /* fieldChanged: */



/*--------------------------- textDidEnd:endChar: ---------------------------*\
*									      *
*	Helping method so that the data is taken from the fields even if      *
*	they are left with TAB.                                               *
*									      *
\*---------------------------------------------------------------------------*/

- textDidEnd:sender endChar:(unsigned short)whyEnd
{
    if (whyEnd == NX_RETURN || whyEnd == NX_TAB || whyEnd == NX_BACKTAB)
	[self fieldChanged:[sender delegate]];
    
    return self;
} /* textDidEnd:endChar: */



@end