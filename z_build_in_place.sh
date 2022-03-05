#!/bin/bash
# to get rid of MSDOS format do this to this file: sudo sed -i s/\\r//g ./filename
# or, open in nano, control-o and then then alt-M a few times to toggle msdos format off and then save
#
set +x
#
# The Raspberry Pi 4, like the Pi3/3+ it contains an Armv8 CPU.  
# Here, assume an Arm8 operating system (64bit) and use ARM8 instructions.
#
# _debug is case sensitive !
_debug=False
#_debug=False
#if [[ "${_debug}" == "True" ]]; then
#	echo "Running in DEBUG mode, you will need to press Enter after each dependency build."
#fi
#
# Build script for x64 ffmpeg on the Pi4 with 64-bit OS which enables h264_v4l2m2m  ?
# as at 2022.02.26
#
# perhaps also see these
# https://forums.raspberrypi.com/viewtopic.php?p=1776531#p1776531
# https://gist.github.com/wildrun0/86a890585857a36c90110cee275c45fd
#
#
### NOTES
#
# We build some libraries form source, but not all.
# Those we do build is because it is the LATEST rather than 
# whatever old version may be in Raspberry Pi debian bullseye x64 repositories
# NOTE NOTE NOTE NOTE we need to 64-bit-ize all of the builds  !!!
# example use:
#/home/pi/FFmpeg/ffmpeg -i /home/pi/final.mp4 -c:v h264_v4l2m2m -b:v 8M -c:a copy test.mp4
#
#
set -x
### PREPARE
# Before we get started, let’s create a directory where we will store the code for each of the libraries.
#
cd ~/Desktop
mkdir ffmpeg_libraries
#

#
### UPDATE THE LINK CACHE
# This command ensures we won’t run into linking issues because the compiler can’t find a library.
#
cd ~/Desktop
sudo ldconfig
#if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
#
### FFMPEG
#
# Use the extra libraries we compiled and installed previously
#
cd ~/Desktop/ffmpeg_libraries
#rm -fvR FFmpeg
#git clone https://github.com/hydra3333/FFmpeg.git FFmpeg
cd FFmpeg
git fetch
git merge
#
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "

touch --no-create libavcodec/v4l2_buffers.o
rm -fv libavcodec/v4l2_buffers.o

touch --no-create libavcodec/v4l2_m2m_enc.c
rm -fv libavcodec/v4l2_m2m_enc.o

touch --no-create libavcodec/v4l2_context.c
rm -fv libavcodec/v4l2_context.o

touch --no-create libavcodec/v4l2_fmt.c
rm -fv libavcodec/v4l2_fmt.o

touch --no-create libavcodec/v4l2_m2m.c
rm -fv libavcodec/v4l2_m2m.o

touch --no-create libavcodec/v4l2_m2m_dec.c
rm -fv libavcodec/v4l2_m2m_dec.o

touch --no-create fftools/cmdutils.c
rm -fv fftools/cmdutils.o

touch --no-create libavutil/opt.c
rm -fv libavutil/opt.o

./configure \
	--extra-version="ffmpeg_for_RPi4B_having_h264_v4l2m2m" \
	--arch=aarch64 --target-os=linux \
	--disable-shared --enable-static --enable-pic --enable-neon --disable-w32threads --enable-pthreads \
	--enable-gpl --enable-version3 --enable-nonfree \
	--prefix=/usr/local \
	--libdir=/usr/local/lib \
	--bindir=/usr/local/bin \
	--extra-cflags=" -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib " \
	--extra-ldflags=" -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib " \
	--extra-libs="-lpthread -lm -latomic" \
	--pkg-config=pkg-config \
	--pkg-config-flags=--static \
	--disable-doc --disable-htmlpages --disable-manpages --disable-podpages --disable-txtpages \
	--disable-avisynth \
	--disable-vapoursynth \
	--disable-libkvazaar \
	--disable-schannel \
	--enable-v4l2-m2m \
	--enable-hardcoded-tables \
	--enable-gray \
	--enable-gmp \
	--enable-gnutls \
	--enable-iconv \
	--enable-libaom \
	--enable-libass \
	--enable-libdav1d \
	--enable-libdrm \
	--enable-libfdk-aac \
	--enable-libmp3lame \
	--enable-libtwolame \
	--enable-libfreetype \
	--enable-libopencore-amrnb \
	--enable-libopencore-amrwb \
	--enable-libopus \
	--enable-librtmp \
	--enable-libsnappy \
	--enable-libsoxr \
	--enable-libssh \
	--enable-libvorbis \
	--enable-libvpx \
	--enable-libzimg \
	--enable-libwebp \
	--enable-libx264 \
	--enable-libx265 \
	--enable-libxml2 \
	--enable-librubberband \
	--enable-libwebp \
	--enable-zlib \
	--enable-lzma \
	--extra-cflags="-DLIBTWOLAME_STATIC" \
	--extra-cflags="-DLIBXML_STATIC"
# "ERROR: vulkan requested but not found" when using this:
#	--enable-vulkan --enable-filter=scale_vulkan --enable-filter=avgblur_vulkan --enable-filter=chromaber_vulkan --enable-filter=overlay_vulkan
make -j$(nproc)
sudo make install
