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

### Update

I was searching around for VirtualBox PS/2 mouse emulation problems and I found this 
driver written for MSDOS. It works with VMWare and VirtualBox and is very small. 
This should be much easier than searching the giant VBOX code base.

 - [New DOS mouse driver for VirtualBox/VMware/ PS/2 mice](https://www.vogons.org/viewtopic.php?t=87486)
 - [git.javispedro.com/cgit/vbados.git/tree/vbox.h](https://git.javispedro.com/cgit/vbados.git/tree/vbox.h)
 
I should be able to make a test application that uses some of these C files to display 
data from the VirtualBox VM in a window in OpenStep. From there, I can try integrating 
it into the original VMWare Fusion only OpenStep mouse driver.

## Open to Help

I have never done any kind of development like this before. So if you are good in C
or otherwise want to help, let me know. Not sure if I will succeed at this.

## I asked ChatGPT

Yes, VirtualBox uses a similar approach but with its own custom communication mechanism for guest-host interaction. Like VMware, VirtualBox provides paravirtualized drivers (called Guest Additions) to improve performance, including mouse handling. However, the specific implementation differs.

Comparison: VMware vs. VirtualBox Guest Communication

Both VMware and VirtualBox use I/O ports and inline assembly for low-level communication between the guest OS and the hypervisor. However, VirtualBox uses its own port-based protocol.

1. VMware’s Approach (Seen in Your Driver)
	•	Uses specific I/O ports (like VMMOUSE_PROTO_PORT) to communicate with the hypervisor.
	•	Uses the inl assembly instruction to send/receive data:

inl %%dx, %%eax


	•	This allows VMware to handle guest mouse input efficiently.

2. VirtualBox’s Approach
	•	VirtualBox also uses I/O ports, but with a different mechanism.
	•	It provides a custom instruction, VMMCALL, for hypervisor communication.
	•	Example of how VirtualBox communicates with the host (in assembly):

mov eax, 0x564D5868  ; 'VMXh' Magic number
mov ebx, param       ; Command parameter
mov ecx, VBOX_PORT   ; VirtualBox port
mov edx, 0x5658      ; Port number
in  eax, dx          ; Read response from VirtualBox


	•	Instead of inl, it may use VMCALL or VMMCALL (depending on the CPU type) to communicate.

Does VirtualBox Have a Similar Mouse Driver?

Yes, VirtualBox includes a paravirtualized mouse driver as part of its Guest Additions.
	•	The VirtualBox mouse driver allows seamless pointer integration, similar to VMware.
	•	Instead of VMMouse, VirtualBox uses VBoxGuest modules.
	•	Some parts of its communication are shared memory-based rather than just I/O ports.

Key Differences

Feature	VMware (VMMouse)	VirtualBox (VBoxMouse)
Communication	I/O ports (inl instruction)	I/O ports + VMCALL / VMMCALL
Magic Number	VMMOUSE_PROTO_MAGIC	'VMXh'
Paravirtualization	Yes (optimized mouse input)	Yes (Guest Additions)
Shared Memory	No (mostly I/O port-based)	Yes, supports shared memory for efficiency

Conclusion
	•	Yes, VirtualBox uses assembly to communicate with the host, but the method differs.
	•	Instead of VMware’s inl-based port I/O, VirtualBox often uses VMCALL/VMMCALL for privileged hypervisor interactions.
	•	If you’re looking to write a VirtualBox-specific mouse driver, you’d need to use VirtualBox’s communication protocol instead of VMware’s.

Would you like help finding VirtualBox’s equivalent mouse driver code? 🚀