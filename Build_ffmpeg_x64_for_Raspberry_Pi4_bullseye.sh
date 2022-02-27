#!/bin/bash
# to get rid of MSDOS format do this to this file: sudo sed -i s/\\r//g ./filename
# or, open in nano, control-o and then then alt-M a few times to toggle msdos format off and then save
#
set -x
#
# The Raspberry Pi 4, like the Pi3/3+ it contains an Armv8 CPU.  
# Here, assume an Arm8 operating system (64bit) and use ARM8 instructions.
#
# _debug is case sensitive !
_debug=True
#_debug=False
if [[ "${_debug}" == "True" ]]; then
	echo "Running in DEBUG mode, you will need to press Enter after each dependency build."
fi
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
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
### PREPARE
# Before we get started, let’s create a directory where we will store the code for each of the libraries.
#
cd ~/Desktop
sudo rm -fvR ffmpeg_libraries
mkdir ffmpeg_libraries
#
#
### Install the ffmpeg and dependency build prerequisites
#
sudo apt -y update
sudo apt -y full-upgrade
#
# sudo apt-cache packagename, eg
# sudo apt-cache search git
#
# Install the packages we need for building
#
sudo apt -y install git
sudo apt -y install autoconf
sudo apt -y install autopoint
sudo apt -y install automake
sudo apt -y install libtool
sudo apt -y install gettext
sudo apt -y install build-essential
sudo apt -y install cmake
sudo apt -y install cmake-curses-gui
sudo apt -y install pkg-config
sudo apt -y install meson
sudo apt -y install nasm
sudo apt -y install texinfo
sudo apt -y install wget
sudo apt -y install yasm
sudo apt -y install doxygen
sudo apt -y install perl
sudo apt -y install graphviz
sudo apt -y install imagemagick
sudo apt -y install libasound2-dev
sudo apt -y install libass-dev
sudo apt -y install libavcodec-dev
sudo apt -y install libavdevice-dev
sudo apt -y install libavfilter-dev
sudo apt -y install libavformat-dev
sudo apt -y install libavutil-dev
sudo apt -y install libfreetype6-dev
sudo apt -y install libgnutls30 libgnutls28-dev libgnutlsxx28 libgnutls-openssl27
sudo apt -y install libunistring-dev
sudo apt -y install libgmp-dev
sudo apt -y install libmp3lame-dev
sudo apt -y install libfdk-aac-dev
sudo apt -y install libopencore-amrnb-dev
sudo apt -y install libopencore-amrwb-dev
sudo apt -y install libopus-dev
sudo apt -y install librtmp-dev
sudo apt -y install libsdl2-dev
sudo apt -y install libsdl2-image-dev
sudo apt -y install libsdl2-mixer-dev
sudo apt -y install libsdl2-net-dev
sudo apt -y install libsdl2-ttf-dev
sudo apt -y install libsnappy-dev
sudo apt -y install libsoxr-dev
sudo apt -y install libssh-dev
sudo apt -y install libssl-dev
sudo apt -y install libv4l-dev
sudo apt -y install libva-dev
sudo apt -y install libvdpau-dev
sudo apt -y install libvo-amrwbenc-dev
sudo apt -y install libvorbis-dev
sudo apt -y install libwebp-dev
sudo apt -y install libdrm-dev
sudo apt -y install libvpx-dev
sudo apt -y install libx264-dev
sudo apt -y install libx265-dev
sudo apt -y install libxcb-shape0-dev
sudo apt -y install libxcb-shm0-dev
sudo apt -y install libxcb-xfixes0-dev
sudo apt -y install libxcb1-dev
sudo apt -y install libxml2-dev
sudo apt -y install lzma-dev
sudo apt -y install python3-dev
sudo apt -y install python3-pip
sudo apt -y install zlib1g-dev
sudo apt -y install sqlite3 sqlite3-doc sqlite3-pcre libsqlite3-mod-impexp libsqlite3-mod-xpath 
sudo apt -y install libsqlite3-dev 
sudo apt -y install libnuma-dev libnuma1
# sudo apt-cache search vulkan
#libvulkan-dev - Vulkan loader library -- development files
#libvulkan1 - Vulkan loader library
#vulkan-tools - Miscellaneous Vulkan utilities
#vulkan-validationlayers - Vulkan validation layers
#vulkan-validationlayers-dev - Vulkan validation layers -- development files
#libgulkan-dev - GLib Vulkan helper library -- development files
#libgulkan-doc - GLib Vulkan helper library -- documentation files
#libgulkan-utils - GLib Vulkan helper library -- utilities
#libprimus-vk1 - vulkan layer library for the primus-vk layer
#primus-vk - Vulkan layer for GPU offloading
#libvkd3d-dev - Direct3D 12 to Vulkan translation - development files
#libvkd3d-utils1 - Direct3D 12 to Vulkan translation - utilities library
#libvkd3d1 - Direct3D 12 to Vulkan translation - library
sudo apt -y install libvulkan1 libvulkan-dev vulkan-tools vulkan-validationlayers vulkan-validationlayers-dev
sudo apt -y install libgulkan-dev libgulkan-doc libgulkan-utils
sudo apt -y install primus-vk libprimus-vk1
sudo apt -y install libvkd3d-dev libvkd3d-utils1 libvkd3d1
#
#libmediainfo-dev - library reading metadata from media files -- headers
#libmediainfo-doc - library for reading metadata from media files -- documentation
#libmediainfo0v5 - library for reading metadata from media files -- shared library
#python3-mediainfodll - library for reading metadata from media files -- shared library
#mediainfo - command-line utility for reading information from audio/video files
#mediainfo-gui - graphical utility for reading information from audio/video files
#python-pymediainfo-doc - documentation for the pymediainfo Python library
#python3-pymediainfo - Library to fetch multimedia metadata information - Python 3.x
sudo apt -y install mediainfo mediainfo-gui
sudo apt -y install libmediainfo-dev libmediainfo-doc libmediainfo0v5
sudo apt -y install python3-mediainfodll
sudo apt -y install python3-pymediainfo python-pymediainfo-doc 
#
#
# Purge the "-dev" pack which we are going to build dependences for ...
# No, this will have a really bad effect of other development and uses.
#sudo apt -y purge libgnutls30 libgnutls28-dev libgnutlsxx28 libgnutls-openssl27
#sudo apt -y purge libgmp-dev
#sudo apt -y purge libmp3lame-dev
#sudo apt -y purge libfdk-aac-dev
#sudo apt -y purge libopus-dev
#sudo apt -y purge libvorbis-dev
#sudo apt -y purge libwebp-dev
#sudo apt -y purge libvpx-dev
#sudo apt -y purge libx264-dev
#sudo apt -y purge libx265-dev
#sudo apt -y purge lzma-dev
#sudo apt -y purge zlib1g-dev
#sudo apt -y purge libsqlite3-dev 
#
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
# FFTW3
# FFTW3 is a free collection of fast C routines for computing the Discrete Fourier Transform in one or more dimensions.
#
cd ~/Desktop/ffmpeg_libraries
rm -fv fftw-3.3.10.tar.gz
rm -fvR fftw-3.3.10
wget https://fossies.org/linux/misc/fftw-3.3.10.tar.gz
tar -xf fftw-3.3.10.tar.gz
cd fftw-3.3.10
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
# these 3 lines are from bootstrap.sh
touch ChangeLog
rm -rfv autom4te.cache
autoreconf --verbose --install --symlink --force
rm -fv config.cache
./configure --prefix=/usr/local --disable-shared --enable-static --disable-silent-rules --disable-doc --disable-alloca --with-our-malloc --disable-fortran \
			--disable-sse --disable-sse2 --disable-avx --disable-avx2 --disable-avx512 --disable-avx-128-fma --disable-altivec --disable-vsx \
			--enable-neon --with-pic \
			--enable-threads --with-combined-threads --disable-float --disable-long-double -disable-quad-precision \
			--enable-armv8-pmccntr-el0 --enable-armv8-cntvct-el0
make -j$(nproc)
sudo make install
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
### GMP
# GMP is a free library for arbitrary precision arithmetic, operating on signed integers, rational numbers, and floating-point numbers. 
# There is no practical limit to the precision except the ones implied by the available memory in the machine GMP runs on.
#
cd ~/Desktop/ffmpeg_libraries
rm -fv gmp-6.2.1.tar.xz
rm -fvR gmp-6.2.1
wget https://fossies.org/linux/misc/gmp-6.2.1.tar.xz
#wget https://gmplib.org/download/gmp/gmp-6.2.1.tar.xz
tar -xf gmp-6.2.1.tar.xz
cd gmp-6.2.1
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
autoreconf -fiv
./configure --prefix=/usr/local --disable-shared --enable-static -enable-assembly=yes --enable-fft=yes 
make -j$(nproc)
make check
sudo make install
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
### ZLIB
# zlib is a general purpose data compression library
#
cd ~/Desktop/ffmpeg_libraries
sudo rm -fvR zlib
git clone --depth 1 https://github.com/madler/zlib.git ./zlib
cd zlib
mkdir -pv _build
cd _build
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
cmake -G "Unix Makefiles" .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=/usr/local/lib -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=0 -D_FILE_OFFSET_BITS=64
make -j$(nproc)
sudo make install
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
### ICONV
# used to convert between different character encodings. 
#
cd ~/Desktop/ffmpeg_libraries
rm -fv libiconv-1.16.tar.gz
sudo rm -fvR libiconv-1.16
wget https://fossies.org/linux/misc/libiconv-1.16.tar.gz
tar -xf libiconv-1.16.tar.gz
cd libiconv-1.16
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
./configure --prefix=/usr/local --disable-shared --enable-static --disable-nls --enable-extra-encodings
make -j$(nproc)
sudo make install
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
# XZ
# XZ Utils provide a general-purpose data-compression library. 
# lzma is an alias for xz.
# xz depends on iconv
#
cd ~/Desktop/ffmpeg_libraries
sudo rm -fvR xz
git clone --depth 1 https://github.com/xz-mirror/xz ./xz
cd xz
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
sh ./autogen.sh
./configure --prefix=/usr/local --disable-shared --enable-static --disable-xz --disable-xzdec --disable-lzmadec --disable-lzmainfo --disable-doc
make -j$(nproc)
sudo make install
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
### ZIMG
# This library implements a range of image processing features, dealing with the basics of scaling, colorspace, and depth.
#
cd ~/Desktop/ffmpeg_libraries
sudo rm -fvR zimg
git clone --depth 1 https://github.com/sekrit-twc/zimg.git ./zimg
cd zimg
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
sh ./autogen.sh 
./configure --prefix=/usr/local --disable-shared --enable-static --disable-testapp --disable-example --disable-unit-test --disable-debug 
make -j$(nproc)
sudo make install
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
### SQLITE3
# SQLite is a C-language library that implements a small, fast, self-contained, high-reliability, full-featured, SQL database engine. 
# SQLite is the most used database engine in the world.
# SQLite is built into all mobile phones and most computers and comes bundled inside countless other applications that people use every day.
#
cd ~/Desktop/ffmpeg_libraries
#rm -fv sqlite-autoconf-3370200.tar.gz
#sudo rm -fvR sqlite-autoconf-3370200
#wget https://fossies.org/linux/misc/sqlite-autoconf-3370200.tar.gz
#tar -xf sqlite-autoconf-3370200.tar.gz
#cd sqlite-autoconf-3370200
rm -fv sqlite-autoconf-3380000.tar.gz
sudo rm -fvR sqlite-autoconf-3380000
wget https://www.sqlite.org/2022/sqlite-autoconf-3380000.tar.gz
tar -xf sqlite-autoconf-3380000.tar.gz
cd sqlite-autoconf-3380000
# https://www.sqlite.org/compile.html
#export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib -fexceptions -DSQLITE_ENABLE_COLUMN_METADATA=ON -DSQLITE_USE_MALLOC_H=ON -DSQLITE_USE_MSIZE=ON -DSQLITE_DISABLE_DIRSYNC=ON -DSQLITE_ENABLE_RTREE=ON -fno-strict-aliasing "
#export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib -fexceptions -DSQLITE_ENABLE_COLUMN_METADATA=ON -DSQLITE_USE_MALLOC_H=ON -DSQLITE_USE_MSIZE=ON -DSQLITE_DISABLE_DIRSYNC=ON -DSQLITE_ENABLE_RTREE=ON -fno-strict-aliasing "
#export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib -fexceptions -DSQLITE_ENABLE_COLUMN_METADATA=ON -DSQLITE_USE_MALLOC_H=ON -DSQLITE_USE_MSIZE=ON -DSQLITE_DISABLE_DIRSYNC=ON -DSQLITE_ENABLE_RTREE=ON -fno-strict-aliasing "
#export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib -fexceptions -DSQLITE_ENABLE_COLUMN_METADATA=ON -DSQLITE_USE_MALLOC_H=ON -DSQLITE_USE_MSIZE=ON -DSQLITE_DISABLE_DIRSYNC=ON -DSQLITE_ENABLE_RTREE=ON -fno-strict-aliasing "
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib -fexceptions -DSQLITE_ENABLE_COLUMN_METADATA=ON  -DSQLITE_DISABLE_DIRSYNC=ON -DSQLITE_ENABLE_RTREE=ON -DSQLITE_DEFAULT_FOREIGN_KEYS=ON -DSQLITE_DEFAULT_FILE_PERMISSIONS=666 -fno-strict-aliasing "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib -fexceptions -DSQLITE_ENABLE_COLUMN_METADATA=ON  -DSQLITE_DISABLE_DIRSYNC=ON -DSQLITE_ENABLE_RTREE=ON -DSQLITE_DEFAULT_FOREIGN_KEYS=ON -DSQLITE_DEFAULT_FILE_PERMISSIONS=666 -fno-strict-aliasing "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib -fexceptions -DSQLITE_ENABLE_COLUMN_METADATA=ON  -DSQLITE_DISABLE_DIRSYNC=ON -DSQLITE_ENABLE_RTREE=ON -DSQLITE_DEFAULT_FOREIGN_KEYS=ON -DSQLITE_DEFAULT_FILE_PERMISSIONS=666 -fno-strict-aliasing "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib -fexceptions -DSQLITE_ENABLE_COLUMN_METADATA=ON  -DSQLITE_DISABLE_DIRSYNC=ON -DSQLITE_ENABLE_RTREE=ON -DSQLITE_DEFAULT_FOREIGN_KEYS=ON -DSQLITE_DEFAULT_FILE_PERMISSIONS=666 -fno-strict-aliasing "
autoreconf -fiv
# sqlite3 takes AGES to configure and build on a Raspberry Pi4, do not worry of it looks like it is freezing
# seemingly OK to ignore:
#sqlite3 shell.c:8188:17: warning: ‘__builtin_memcmp_eq’ specified size between 18446744071562067968 and 18446744073709551615 exceeds maximum object size 9223372036854775807 [-Wstringop-overflow=]
./configure --prefix=/usr/local --disable-shared --enable-static --enable-threadsafe --disable-editline --enable-readline --enable-json1 --enable-fts5 --enable-session
make -j$(nproc)
sudo make install
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
### LIBFLAC
# libFLAC is an Open Source lossless audio codec 
#
cd ~/Desktop/ffmpeg_libraries
sudo rm -fvR libflac
git clone --depth 1 https://github.com/xiph/flac.git ./libflac
cd libflac
mkdir -pv _build
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
sed -i 's|libtool |libtoolize |g' ./autogen.sh
sh autogen.sh --no-symlink
cd _build
cmake -G "Unix Makefiles" .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=/usr/local/lib -DWITH_OGG=ON -DBUILD_DOCS=OFF -DWITH_STACK_PROTECTOR=ON -DENABLE_64_BIT_WORDS=ON -DBUILD_PROGRAMS=OFF -DINSTALL_PKGCONFIG_MODULES=ON -DINSTALL_MANPAGES=OFF -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF -DBUILD_EXAMPLES=OFF -DVERSION=1.3.4 -DCMAKE_BUILD_TYPE=Release -DHAVE_SQLITE3=ON 
make -j$(nproc)
sudo make install
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
### LIBOPUS
# Opus is a codec for interactive speech and audio transmission over the Internet.
#
cd ~/Desktop/ffmpeg_libraries
sudo rm -fvR libopus
git clone --depth 1 https://github.com/xiph/opus.git ./libopus
cd libopus
mkdir -pv _build
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
sh ./autogen.sh
cd _build
cmake -G "Unix Makefiles" .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=/usr/local/lib -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF -DOPUS_CUSTOM_MODES=ON -DOPUS_BUILD_PROGRAMS=OFF -DOPUS_INSTALL_PKG_CONFIG_MODULE=ON -DHAVE_SQLITE3=ON
make -j$(nproc)
sudo make install
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
### LIBOGG
# Ogg project codecs use the Ogg bitstream format to arrange the raw, compressed bitstream into a more robust, useful form
#
cd ~/Desktop/ffmpeg_libraries
sudo rm -fvR libogg
git clone --depth 1 https://github.com/xiph/ogg.git ./libogg
cd libogg
mkdir -pv _build
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
sh ./autogen.sh
cd _build
cmake -G "Unix Makefiles" .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=/usr/local/lib -DBUILD_SHARED_LIBS=OFF -DINSTALL_DOCS=OFF -DCMAKE_BUILD_TYPE=Release -DHAVE_SQLITE3=ON 
make -j$(nproc)
sudo make install
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
### LIBVORBIS
# Vorbis is a general purpose audio and music encoding format contemporary to 
# MPEG-4's AAC and TwinVQ, the next generation beyond MPEG audio layer 3. 
# depends_on 'libogg'
#
cd ~/Desktop/ffmpeg_libraries
sudo rm -fvR libvorbis
git clone --depth 1 https://github.com/xiph/vorbis ./libvorbis
cd libvorbis
mkdir -pv _build
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
sh ./autogen.sh
cd _build
cmake -G "Unix Makefiles" .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=/usr/local/lib -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DHAVE_SQLITE3=ON
make -j$(nproc)
sudo make install
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
### LIBSAMPLERATE
# libsamplerate (also known as Secret Rabbit Code) is a library for performing sample rate conversion of audio data.
# depends_on 'libflac', 'fftw3', 'libopus'
#
cd ~/Desktop/ffmpeg_libraries
sudo rm -fvR libsamplerate
git clone --depth 1 https://github.com/erikd/libsamplerate.git ./libsamplerate
cd libsamplerate
mkdir -pv _build
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
sh ./autogen.sh
cd _build
cmake -G "Unix Makefiles" .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=/usr/local/lib -DLIBSAMPLERATE_EXAMPLES=OFF -DBUILD_TESTING=OFF -DLIBSAMPLERATE_TESTS=OFF -DBUILD_SHARED_LIBS=OFF -DLIBSAMPLERATE_ENABLE_SANITIZERS=OFF -DHAVE_SQLITE3=ON -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
#make check
sudo make install
#sudo ldconfig -v
sudo ldconfig
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
### LIBSNDFILE
# libsndfile is a C library for reading and writing files containing sampled audio data
#
cd ~/Desktop/ffmpeg_libraries
sudo rm -fvR libsndfile
git clone --depth 1 https://github.com/libsndfile/libsndfile.git ./libsndfile
cd libsndfile
mkdir -pv _build
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
sh ./autogen.sh
cd _build
cmake -G "Unix Makefiles" .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=/usr/local/lib -DBUILD_SHARED_LIBS=OFF -DBUILD_PROGRAMS=OFF -DBUILD_TESTING=OFF -DBUILD_EXAMPLES=OFF -DENABLE_BOW_DOCS=OFF -DENABLE_PACKAGE_CONFIG=ON -DCMAKE_BUILD_TYPE=Release -DHAVE_ALSA_ASOUNDLIB_H=OFF -DENABLE_EXTERNAL_LIBS=ON -DHAVE_SQLITE3=ON
make -j$(nproc)
sudo make install
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
### VAMP_PLUGIN
# Vamp is an easy system to develop plugins for. 
# It has a standard cross-platform SDK which includes API documentation, example plugins, ready-to-use C++ base classes, the C API header, and a test host.
# Vamp plugins use a C binary interface for the greatest level of binary compatibility. 
#
cd ~/Desktop/ffmpeg_libraries
rm -fv vamp-plugin-sdk-2.9.0.tar.gz
sudo rm -fvR vamp-plugin-sdk-2.9.0
wget https://raw.githubusercontent.com/hydra3333/h3333_python_cross_compile_script_v100/master/sources/vamp-plugin-sdk-2.9.0.tar.gz
#wget https://code.soundsoftware.ac.uk/attachments/download/2588/vamp-plugin-sdk-2.9.0.tar.gz
tar -xf vamp-plugin-sdk-2.9.0.tar.gz
cd vamp-plugin-sdk-2.9.0
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
autoreconf -fiv
./configure sdkstatic --libdir=/usr/local/lib --disable-programs
make -j$(nproc)
# there is no "make install" which works, so do it the hard way
sudo cp -fv libvamp-sdk.a /usr/local/lib/
sudo cp -fv libvamp-hostsdk.a /usr/local/lib/
sudo cp -fRv vamp-hostsdk/ /usr/local/include/
sudo cp -fRv vamp-sdk/ /usr/local/include/
sudo cp -fRv vamp/ /usr/local/include/
sudo cp -fv pkgconfig/vamp.pc.in /usr/local/lib/pkgconfig/vamp.pc
sudo cp -fv pkgconfig/vamp-hostsdk.pc.in /usr/local/lib/pkgconfig/vamp-hostsdk.pc
sudo cp -fv pkgconfig/vamp-sdk.pc.in /usr/local/lib/pkgconfig/vamp-sdk.pc
sudo sed -i 's|\%PREFIX\%|/usr/local|' /usr/local/lib/pkgconfig/vamp.pc
sudo sed -i 's|\%PREFIX\%|/usr/local|' /usr/local/lib/pkgconfig/vamp-hostsdk.pc
sudo sed -i 's|\%PREFIX\%|/usr/local|' /usr/local/lib/pkgconfig/vamp-sdk.pc
#cat /usr/local/lib/pkgconfig/vamp.pc
#cat /usr/local/lib/pkgconfig/vamp-hostsdk.pc
#cat /usr/local/lib/pkgconfig/vamp-sdk.pc
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
### RUBBERBAND
# An audio time-stretching and pitch-shifting library and utility program.
# depends on 'libsamplerate', 'libopus', 'libogg', 'libvorbis', 'libflac', 'libsndfile', 'vamp_plugin', 'fftw3'
#
cd ~/Desktop/ffmpeg_libraries
sudo rm -fvR rubberband
wget https://raw.githubusercontent.com/hydra3333/h3333_python_cross_compile_script_v100/master/additional_headers/ladspa.h
sudo mv -fv ladspa.h /usr/local/include/ladspa.h
git clone --depth 1 https://github.com/breakfastquay/rubberband.git ./rubberband
cd rubberband
mkdir -pv build
cd build
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
# building the command-line utility aborts, so do not build it
sed -i 's|if have_sndfile|#if have_sndfile # building the command-line utility aborts, so do not build it\nif false|' ../meson.build
meson ./ .. --libdir=/usr/local/lib --backend=ninja --default-library=static --buildtype=release -Dno_shared=true -Dresampler=libsamplerate -DHAVE_LIBSAMPLERATE=true -DUSE_PTHREADS=true -DHAVE_POSIX_MEMALIGN=true -Dfft=fftw -DHAVE_FFTW3=true
ninja
sudo ninja install
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
### FDK-AAC
# Compile the Fraunhofer FDK AAC library.
# Compiling this library will allow FFmpeg to have support for the AAC sound format.
#
cd ~/Desktop/ffmpeg_libraries
sudo rm -fvR fdk-aac
git clone --depth 1 https://github.com/mstorsjo/fdk-aac.git ./fdk-aac
cd fdk-aac
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
sh ./autogen.sh
mkdir -pv build
cd build
cmake -G "Unix Makefiles" .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=/usr/local/lib -DBUILD_SHARED_LIBS=OFF -DBUILD_PROGRAMS=OFF -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
sudo make install
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
### LAME
# For mp3 encoding
#
cd ~/Desktop/ffmpeg_libraries
rm -fv lame-3.100.tar.gz
sudo rm -fvR lame-3.100
wget https://fossies.org/linux/misc/lame-3.100.tar.gz
tar -xf lame-3.100.tar.gz
cd lame-3.100
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
autoreconf -fiv
./configure --prefix=/usr/local --disable-shared --enable-static --enable-nasm --disable-frontend --disable-rpath --disable-cpml --disable-gtktest --disable-mp3x --disable-mp3rtp --disable-dynamic-frontends --disable-expopt --disable-debug
make -j$(nproc)
sudo make install
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
### TWOLAME
# TwoLAME is an optimized MPEG Audio Layer 2 (MP2) encoder
#
cd ~/Desktop/ffmpeg_libraries
rm -fv twolame-0.4.0.tar.gz
sudo rm -fvR twolame-0.4.0
wget https://github.com/njh/twolame/releases/download/0.4.0/twolame-0.4.0.tar.gz
tar -xf twolame-0.4.0.tar.gz
cd twolame-0.4.0
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -DLIBTWOLAME_STATIC"
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -DLIBTWOLAME_STATIC"
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -DLIBTWOLAME_STATIC"
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -DLIBTWOLAME_STATIC"
# building the frontend aborts, so try not build it (this one SED does not manage it)
#sed -i 's|if test "x$HAVE_SNDFILE" = "xyes"; then|#if test "x$HAVE_SNDFILE" = "xyes"; then # building the frontend aborts, so do not build it\nif test "no" = "yes"; then|' ./configure.ac
sed -i 's|AC_SUBST(TWOLAME_BIN)|TWOLAME_BIN=""\nAC_SUBST(TWOLAME_BIN)|' ./configure.ac
sed -i '/frontend\/Makefile/d' ./configure.ac
sed -i '/simplefrontend\/Makefile/d' ./configure.ac
sed -i '/tests\/Makefile/d' ./configure.ac
sed -i 's/libtwolame frontend simplefrontend doc tests/libtwolame/' ./Makefile.am
# Do the autoreconf AFTER the SED's above
autoreconf -fiv
# NOTE: ALSO ... This switch by itself without the SEDs prevents build of front-ends : --disable-sndfile
./configure --prefix=/usr/local --disable-shared --enable-static --enable-sndfile
make -j$(nproc)
sudo make install
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
### DAV1D
# This library will add support for decoding the AV1 video format into FFmpeg. 
# This codec is considered the successor of the VP9 codec and as a competitor to the x265 codec.
#
cd ~/Desktop/ffmpeg_libraries
sudo rm -fvR dav1d
git clone --depth 1 https://code.videolan.org/videolan/dav1d.git ./dav1d
cd dav1d
mkdir -pv build
cd build
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
meson ./ .. --libdir=/usr/local/lib --backend=ninja --default-library=static --strip -Denable_tools=false -Denable_tests=false -Denable_examples=false -Denable_docs=false -Dtestdata_tests=false --buildtype=release
ninja
sudo ninja install
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
### LIBX264 multibit
# This library will add support for libx264 encoding 
#
cd ~/Desktop/ffmpeg_libraries
sudo rm -fvR libx264
git clone --depth 1 https://code.videolan.org/videolan/x264.git ./libx264
mkdir -pv libx264
cd libx264
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
./configure --prefix=/usr/local --enable-static --enable-strip --enable-lto --enable-pic --bit-depth=all --chroma-format=all --disable-win32thread --extra-cflags="-DLIBXML_STATIC" --extra-cflags="-DGLIB_STATIC_COMPILATION" --disable-cli --disable-lavf --disable-avs --disable-ffms --disable-gpac --disable-lsmash --disable-opencl
make -j$(nproc)
sudo make install
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
### LIBX265 multibit
# This library will add support for libx265 encoding 
#
cd ~/Desktop/ffmpeg_libraries
# for this dependency, first remove what is usually installed.
sudo rm -fv /usr/local/lib/libx265.a
sudo rm -fv /usr/local/lib/libhdr10plus.a
sudo rm -fv /usr/local/include/x265.h
sudo rm -fv /usr/local/include/x265_config.h
sudo rm -fv /usr/local/include/hdr10plus.h
sudo rm -fv /usr/local/lib/libx265_main.a
sudo rm -fv /usr/local/lib/libx265_main10.a
sudo rm -fv /usr/local/lib/libx265_main12.a
sudo rm -fv /usr/local/lib/pkgconfig/x265.pc
#
sudo rm -fvR libx265
git clone --depth 1 https://bitbucket.org/multicoreware/x265_git ./libx265
cd libx265
cd build/linux
ls -al
#
mkdir -pv ./8bit_multibit
mkdir -pv ./10bit
mkdir -pv ./12bit
#
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
#
cd ./12bit
cmake -G "Unix Makefiles" ../../../source  \
			-DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=/usr/local/lib \
			-DENABLE_ASSEMBLY=ON \
			-DHIGH_BIT_DEPTH=ON \
			-DENABLE_HDR10_PLUS=ON \
			-DENABLE_SHARED=OFF \
			-DEXPORT_C_API=OFF \
			-DENABLE_CLI=OFF \
			-DMAIN12=ON \
			-DLIBXML_STATIC=ON \
			-DGLIB_STATIC_COMPILATION=ON
make -j$(nproc)
ls -al
sudo make install
mv -fv "./libx265.a" "./libx265_main12.a"
#
cd ..
cd ./10bit
cmake -G "Unix Makefiles" ../../../source \
			-DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=/usr/local/lib \
			-DENABLE_ASSEMBLY=ON \
			-DHIGH_BIT_DEPTH=ON \
			-DENABLE_HDR10_PLUS=ON \
			-DENABLE_SHARED=OFF \
			-DEXPORT_C_API=OFF \
			-DENABLE_CLI=OFF \
			-DLIBXML_STATIC=ON \
			-DGLIB_STATIC_COMPILATION=ON
make -j$(nproc)
ls -al
sudo make install
mv -fv "./libx265.a" "./libx265_main10.a"
#
cd ..
cd ./8bit_multibit
#
#ln -sf ../10bit/libx265.a libx265_main10.a
#ln -sf ../12bit/libx265.a libx265_main12.a
#-DEXTRA_LIB="x265_main10.a;x265_main12.a"  -DCMAKE_INSTALL_LIBDIR=/usr/local/lib -DEXTRA_LINK_FLAGS=-L.
#
cp -fv "../10bit/libx265_main10.a"        ./libx265_main10.a
cp -fv "../12bit/libx265_main12.a"        ./libx265_main12.a
#
cmake -G "Unix Makefiles" ../../../source \
			-DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=/usr/local/lib \
			-DENABLE_ASSEMBLY=ON \
			-DENABLE_HDR10_PLUS=ON \
			-DENABLE_SHARED=OFF \
			-DENABLE_CLI:BOOL=OFF \
			-DEXTRA_LIB="x265_main10.a;x265_main12.a" \
			-DEXTRA_LINK_FLAGS="-L.;-L../10bit;-L../12bit" \
			-DLINKED_10BIT=ON \
			-DLINKED_12BIT=ON \
			-DLIBXML_STATIC=ON \
			-DGLIB_STATIC_COMPILATION=ON
make -j$(nproc)
mv -fv "./libx265.a" "./libx265_main.a"
ar -M <<EOF
CREATE libx265.a
ADDLIB libx265_main.a
ADDLIB libx265_main10.a
ADDLIB libx265_main12.a
SAVE
END
EOF
# Create a new x265.pc ... somehow it is not created on Raspberry Pi
#cp ../../../source/x265.pc.in ./x265.pc
#sed -i 's|\@CMAKE_INSTALL_PREFIX\@|/usr/local|' ./x265.pc
#sed -i 's|\@LIB_INSTALL_DIR\@|lib|' ./x265.pc
#sed -i 's|\@CMAKE_PROJECT_NAME\@|x265|' ./x265.pc
#sed -i 's|\@X265_LATEST_TAG\@|3.5|' ./x265.pc
#sed -i 's|\@PRIVATE_LIBS\@|-lstdc++ -lssp_nonshared -lssp -lgcc -lgcc|' ./x265.pc
#sudo apt -y install libx265-dev
cp -fv /usr/lib/aarch64-linux-gnu/pkgconfig/x265.pc ./x265.pc
#sudo apt -y purge libx265-dev
sed -i 's|prefix=\/usr|prefix=\/usr\/local|' ./x265.pc
sed -i 's|\/aarch64-linux-gnu||' ./x265.pc
sed -i 's|Version: 3.4|Version: 3.5|' ./x265.pc
##sed -i 's|-lnuma||' ./x265.pc
cat ./x265.pc
# re-install the new composite libx265.a created by "ar"
sudo make install
sudo cp -fv ./libx265_main.a	/usr/local/lib/
sudo cp -fv ./libx265_main10.a	/usr/local/lib/
sudo cp -fv ./libx265_main12.a	/usr/local/lib/
sudo cp -fv ./x265.pc			/usr/local/lib/pkgconfig/x265.pc
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
# LIBPNG
# Support for the PNG image format
# libpng depends on zlib
#
cd ~/Desktop/ffmpeg_libraries
sudo rm -fvR libpng-1.6.37
rm -fv lame-3.100.tar.gz
sudo rm -fvR libpng-1.6.37
wget https://fossies.org/linux/misc/libpng-1.6.37.tar.xz
#wget https://sourceforge.net/projects/libpng/files/libpng16/1.6.37/libpng-1.6.37.tar.xz
tar -xf libpng-1.6.37.tar.xz
cd libpng-1.6.37
mkdir -pv _build
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
sh ./autogen.sh
cd _build
cmake -G "Unix Makefiles" .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=/usr/local/lib -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DBUILD_BINARY=OFF -DPNG_TESTS=OFF -DPNG_SHARED=OFF -DPNG_STATIC=ON -DPNG_HARDWARE_OPTIMIZATIONS=ON
make -j$(nproc)
sudo make install
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
# LIBJPEG-TURBO
# libjpeg-turbo is a JPEG image codec that uses SIMD instructions to accelerate 
# baseline JPEG compression and decompression as well as progressive JPEG compression on x86, x86-64, and Arm systems.
# On such systems, libjpeg-turbo is generally 2-6x as fast as libjpeg, all else being equal.
cd ~/Desktop/ffmpeg_libraries
sudo rm -fvR libjpeg-turbo
git clone --depth 1 https://github.com/libjpeg-turbo/libjpeg-turbo.git ./libjpeg-turbo
cd libjpeg-turbo
mkdir -pv _build
cd _build
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
cmake -G "Unix Makefiles" .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=/usr/local/lib -DCMAKE_BUILD_TYPE=Release -DENABLE_STATIC=ON -DENABLE_SHARED=OFF -DREQUIRE_SIMD=ON -DWITH_SIMD=ON -DWITH_JAVA=OFF 
make -j$(nproc)
sudo make install
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
# LIBWEBP
# Support for the WebP image format
# libwebp depends on libpng libjpeg-turbo
#
cd ~/Desktop/ffmpeg_libraries
sudo rm -fvR libwebp
git clone --depth 1 https://chromium.googlesource.com/webm/libwebp ./libwebp
cd libwebp
mkdir -pv _build
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
sed -i.bak 's/\$LIBPNG_CONFIG /\$LIBPNG_CONFIG --static /g' ./configure.ac # fix building with libpng 
sh ./autogen.sh
cd _build
cmake -G "Unix Makefiles" .. -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=/usr/local/lib -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release \
	-DWEBP_NEAR_LOSSLESS=ON \
	-DWEBP_UNICODE=ON \
	-DWEBP_BUILD_CWEBP=OFF \
	-DWEBP_BUILD_DWEBP=OFF \
	-DWEBP_BUILD_VWEBP=OFF \
	-DWEBP_BUILD_WEBPINFO=OFF \
	-DWEBP_BUILD_WEBPMUX=OFF \
	-DWEBP_BUILD_EXTRAS=OFF \
	-DWEBP_BUILD_ANIM_UTILS=OFF \
	-DWEBP_BUILD_GIF2WEBP=OFF \
	-DWEBP_BUILD_IMG2WEBP=OFF \
	-DWEBP_BUILD_WEBP_JS=OFF \
	-DWEBP_ENABLE_SWAP_16BIT_CSP=ON 
make -j$(nproc)
sudo make install
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
# LIBVPX
# Support for the VP8 and VP9 video codecs on our Raspberry Pi.
# This library we are compiling is called LibVPX and is developed by Google.
#
cd ~/Desktop/ffmpeg_libraries
sudo rm -fvR libvpx
git clone --depth 1 https://chromium.googlesource.com/webm/libvpx ./libvpx
cd libvpx
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
./configure --prefix=/usr/local --disable-shared --enable-static --enable-webm-io --enable-libyuv --enable-vp9 --enable-vp8 --enable-postproc --enable-vp9-highbitdepth --enable-vp9-postproc --enable-postproc-visualizer --enable-error-concealment --enable-better-hw-compatibility --enable-multi-res-encoding --enable-vp9-temporal-denoising --disable-tools --disable-docs --disable-examples --disable-install-docs --disable-unit-tests --disable-decode-perf-tests --disable-encode-perf-tests
make -j$(nproc)
sudo make install
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
cd ~/Desktop/ffmpeg_libraries
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
### kvazaar
# This is an HEVC encoder called “kvazaar“.
#
#cd ~/Desktop
#sudo rm -fvR kvazaar
#git clone --depth 1 https://github.com/ultravideo/kvazaar.git ./kvazaar
#cd kvazaar
#export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
#export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
#export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
#export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
#sh ./autogen.sh
#./configure --prefix=/usr/local --disable-shared --enable-static 
#make -j$(nproc)
#sudo make install
#export -n CFLAGS
#export -n CXXFLAGS
#export -n CPPFLAGS
#export -n LDFLAGS
#cd ~/Desktop/ffmpeg_libraries
#
# LIBAOM
# This library adds support for encoding to the AP1 video codec
#									
cd ~/Desktop/ffmpeg_libraries
sudo rm -fvR aom
git clone --depth 1 https://aomedia.googlesource.com/aom ./aom
cd aom
mkdir -pv aom_build
cd aom_build
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
cmake -G "Unix Makefiles" AOM_SRC -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_INSTALL_LIBDIR=/usr/local/lib \
-DCMAKE_BUILD_TYPE=Release \
-DPYTHON_EXECUTABLE="$(which python3)" \
-DBUILD_SHARED_LIBS=0 \
-DCONFIG_STATIC=1 \
-DCONFIG_SHARED=0 \
-DFORCE_HIGHBITDEPTH_DECODING=1 \
-DCONFIG_AV1_HIGHBITDEPTH=1 \
-DHAVE_PTHREAD_H=1 \
-DCONFIG_LIBYUV=1 \
-DCONFIG_MULTITHREAD=1 \
-DCONFIG_PIC=1 \
-DCONFIG_COEFFICIENT_RANGE_CHECKING=1 \
-DCONFIG_DENOISE=1 \
-DCONFIG_WEBM_IO=1 \
-DCONFIG_SPATIAL_RESAMPLING=1 \
-DENABLE_NASM=1 \
-DCONFIG_AV1_DECODER=1 \
-DCONFIG_AV1_ENCODER=1 \
-DENABLE_TOOLS=0 \
-DENABLE_EXAMPLES=0 \
-DENABLE_DOCS=0 \
-DENABLE_TESTS=0 \
-DENABLE_TESTDATA=0 \
-DAOM_EXTRA_C_FLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib " \
-DAOM_EXTRA_CXX_FLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib " \
-DLIBXML_STATIC=1 \
-DGLIB_STATIC_COMPILATION=1 \
..
make -j$(nproc)
sudo make install
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
### UPDATE THE LINK CACHE
# This command ensures we won’t run into linking issues because the compiler can’t find a library.
#
cd ~/Desktop
sudo ldconfig
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
#
### FFMPEG
#
# Use the extra libraries we compiled and installed previously
#
cd ~/Desktop/ffmpeg_libraries
sudo rm -fvR FFmpeg
##git clone --branch release/4.4 --depth 1 https://github.com/FFmpeg/FFmpeg.git ./FFmpeg
git clone --depth 1 https://github.com/FFmpeg/FFmpeg.git ./FFmpeg
cd FFmpeg
## https://forums.raspberrypi.com/viewtopic.php?p=1780625#p1780625
## APPLY PATCH FOR codec h264_v4l2m2m TO REPEAT SEQUENCE HEADERS
#patch -b -Np1 <<EOF
#diff --git a/libavcodec/v4l2_m2m_enc.c b/libavcodec/v4l2_m2m_enc.c
#index f644b50133..4b2ca7bdf4 100644
#--- a/libavcodec/v4l2_m2m_enc.c
#+++ b/libavcodec/v4l2_m2m_enc.c
#@@ -197,6 +197,7 @@ static int v4l2_prepare_encoder(V4L2m2mContext *s)
#     v4l2_set_ext_ctrl(s, MPEG_CID(BITRATE) , avctx->bit_rate, "bit rate", 1);
#     v4l2_set_ext_ctrl(s, MPEG_CID(FRAME_RC_ENABLE), 1, "frame level rate control", 0);
#     v4l2_set_ext_ctrl(s, MPEG_CID(GOP_SIZE), avctx->gop_size,"gop size", 1);
#+    v4l2_set_ext_ctrl(s, MPEG_CID(REPEAT_SEQ_HEADER), 1,"repeat parameter sets", 1);
# 
#     av_log(avctx, AV_LOG_DEBUG,
#         "Encoder Context: id (%d), profile (%d), frame rate(%d/%d), number b-frames (%d), "
#EOF
#diff -U 10 libavcodec/v4l2_m2m_enc.c.orig libavcodec/v4l2_m2m_enc.c
#ls -al libavcodec/v4l2_m2m_enc.*
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
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
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS
if [[ "${_debug}" == "True" ]]; then read -p "Press ENTER to continue"; fi
#
#
# ffmpeg Tests:
#
# Looking for h264_v4l2m2m
#/usr/local/bin/ffmpeg -hide_banner -formats            # show available formats
#/usr/local/bin/ffmpeg -hide_banner -muxers             # show available muxers
#/usr/local/bin/ffmpeg -hide_banner -demuxers           # show available demuxers
#/usr/local/bin/ffmpeg -hide_banner -devices            # show available devices
#/usr/local/bin/ffmpeg -hide_banner -codecs             # show available codecs
#/usr/local/bin/ffmpeg -hide_banner -decoders           # show available decoders
#/usr/local/bin/ffmpeg -hide_banner -encoders           # show available encoders
#/usr/local/bin/ffmpeg -hide_banner -bsfs               # show available bit stream filters
#/usr/local/bin/ffmpeg -hide_banner -protocols          # show available protocols
#/usr/local/bin/ffmpeg -hide_banner -filters            # show available filters
#/usr/local/bin/ffmpeg -hide_banner -pix_fmts           # show available pixel formats
#/usr/local/bin/ffmpeg -hide_banner -layouts            # show standard channel layouts
#/usr/local/bin/ffmpeg -hide_banner -sample_fmts        # show available audio sample formats
#/usr/local/bin/ffmpeg -hide_banner -dispositions       # show available stream dispositions
#/usr/local/bin/ffmpeg -hide_banner -colors             # show available color names
#/usr/local/bin/ffmpeg -hide_banner -sources device     # list sources of the input device
#/usr/local/bin/ffmpeg -hide_banner -sinks device       # list sinks of the output device
#/usr/local/bin/ffmpeg -hide_banner -hwaccels           # show available HW acceleration methods
#/usr/local/bin/ffmpeg -hide_banner -h filter=yadif     # show information about filter
#
/usr/local/bin/ffmpeg -v debug -version
/usr/local/bin/ffmpeg -hide_banner -v quiet -codecs   | grep v4l2
/usr/local/bin/ffmpeg -hide_banner -v quiet -decoders | grep v4l2
/usr/local/bin/ffmpeg -hide_banner -v quiet -encoders | grep v4l2
/usr/local/bin/ffmpeg -hide_banner -v quiet -hwaccels
/usr/local/bin/ffmpeg -hide_banner -v quiet -init_hw_device list
/usr/local/bin/ffmpeg -hide_banner -h decoder=h264_v4l2m2m 
/usr/local/bin/ffmpeg -hide_banner -h encoder=h264_v4l2m2m 
#
v4l2-ctl --list-devices
v4l2-ctl -d /dev/video11 -l
v4l2-ctl -d /dev/video11 --all
#
## EXAMPLE transcode commandline converting from interlaced to progressive:
#
##yadif:mode:parity:deint
##mode 0, send_frame Output one frame for each frame.
##mode 1, send_field Output one frame for each field.
##parity 0=TFF 1=BFF 0=AUTO
##deint 0, all Deinterlace all frames.
##deint 1, interlaced Only deinterlace frames marked as interlaced.
##yadif:0:0:0 = Output one frame for each frame, incoming is TFF, Deinterlace all frames
##yadif:1:0:0 = Output one frame for each field, incoming is TFF, Deinterlace all frames (doubles framerate)
#
#/usr/local/bin/ffmpeg -hide_banner -nostats -v verbose \
#		-i "./some_test_input_file.mp4" \
#		-vsync cfr \
#		-sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp \
#		-strict experimental \
#		-filter_complex "[0:v]yadif=0:0:0,format=pix_fmts=yuv420p" \
#		-c:v h264_v4l2m2m -pix_fmt yuv420p \
#		-g:v 25 \
#		-keyint_min 5 \
#		-b:v 4000000 -minrate:v 500000 -maxrate:v 5000000 -bufsize:v 5000000 \
#		-level 5.2 \
#		-movflags +faststart+write_colr \
#		-an \
#		-y "./some_test_input_file_transcoded.mp4" 2>&1 | tee ff.log
#
#mediainfo "./some_test_input_file.mp4"
#mediainfo "./some_test_input_file_transcoded.mp4"#
#
### -num_capture_buffers 16 -num_output_buffers 32
#
#/usr/local/bin/ffprobe -hide_banner -i "./some_test_input_file.mp4" -probesize 200M -analyzeduration 200M 2>&1 | tee -a ff.log
#/usr/local/bin/ffprobe -hide_banner -i "./some_test_input_file_transcoded.mp4" -probesize 200M -analyzeduration 200M 2>&1 | tee -a ff.log
