# Build ffmpeg x64 for the 64bit Raspberry Pi OS (bullseye)

The Raspberry Pi 4, like the Pi3/3+, contains an Armv8 CPU. Here, we assume an Arm8 operating system (64 bit) and build some dependencies to use ARM8-specific instructions.

OK, I started tinkering with building a "bleeding edge version" [gpl3, non-distributable] static 64-bit ffmpeg under 64-bit bullseye (a work in progress).

It builds some of ffmpeg's dependencies from the latest "bleeding edge" sources (mostly git), so as not to depend too much on what can come from the Raspberry Pi OS repositories (which can sometimes be a few versions behind).   

The rest of the dependencies are pre-installed from Raspberry Pi OS repositories via ```sudo apt-y install``` (usually ```\*-dev```).

Hopefully the resulting x64 ffmpeg enables h264_v4l2m2m gpu hardware accelerated encoding of h.264.

Perhaps also see these:   
https://forums.raspberrypi.com/viewtopic.php?p=1776531#p1776531
https://gist.github.com/wildrun0/86a890585857a36c90110cee275c45fd

## We do this build because:   

It uses the LATEST updated source rather than whatever old version may be in Raspberry Pi debian bullseye x64 repositories.

## Beware:   

Encoding video to AV1 (AOM encoder) takes FOREVER on an AMD 3900X at 4000Ghz (eg 1 to 2 fps)   
... let alone runnit int on a little Raspberry Pi 4 ;)   

