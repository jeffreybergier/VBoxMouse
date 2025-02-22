# VBoxMouse
An optimistic project to make a OPENSTEP mouse driver for VirtualBox. 
This is a project where I will attempt to use the VMMouse driver for OPENSTEP
as a base, but adapt the driver to read the mouse data out of VirtualBox instead.
I think this project is needed at this point, because the VirtualBox PS/2 Mouse
emulation is getting pretty bad. I have a lot of problems with it, specifically
when screen sharing via RDP or when the host system has a retina display. The PS/2
mouse emulator does not scale correctly.