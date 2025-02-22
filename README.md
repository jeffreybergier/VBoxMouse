# VBoxMouse

An optimistic project to make a OPENSTEP mouse driver for VirtualBox. 
This is a project where I will attempt to use the VMMouse driver for OPENSTEP
as a base, but adapt the driver to read the mouse data out of VirtualBox instead.
I think this project is needed at this point, because the VirtualBox PS/2 Mouse
emulation is getting pretty bad. I have a lot of problems with it, specifically
when screen sharing via RDP or when the host system has a retina display. The PS/2
mouse emulator does not scale correctly.

## Approach

The VMMouse driver for VMWare Fusion uses DriverKit to move the mouse around by
communicating with the virtual machine host via designated memory addresses that
can be used to share small amounts of data between the guest and the host.

This file has the assembly code that communicates with VMWare
 - [VMMouse/VMMouse_reloc.tproj/vmmouse_proto.c](VMMouse/VMMouse_reloc.tproj/vmmouse_proto.c)

So I need to replace this file with code that can communicate with VirtualBox.
I haven't fully figured out how to do this yet, but I was scouring the VBox source
code and I found these candidates

 - [/src/VBox/Additions/common/VBoxGuest/lib/VBoxGuestR3LibMouse.cpp](https://github.com/mirror/vbox/blob/74117a1cb257c00e2a92cf522e8e930bd1c4d64b/src/VBox/Additions/common/VBoxGuest/lib/VBoxGuestR3LibMouse.cpp#L53)
 - [/src/VBox/Additions/common/VBoxGuest/lib/VBoxGuestR3LibInternal.h](https://github.com/mirror/vbox/blob/74117a1cb257c00e2a92cf522e8e930bd1c4d64b/src/VBox/Additions/common/VBoxGuest/lib/VBoxGuestR3LibInternal.h#L61)
 - [/include/VBox/VMMDev.h](https://github.com/mirror/vbox/blob/74117a1cb257c00e2a92cf522e8e930bd1c4d64b/include/VBox/VMMDev.h#L1946)

## Open to Help

I have never done any kind of development like this before. So if you are good in C
or otherwise want to help, let me know. Not sure if I will succeed at this.
