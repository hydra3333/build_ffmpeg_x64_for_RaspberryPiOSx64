#!/bin/bash
# to get rid of MSDOS format do this to this file: sudo sed -i s/\\r//g ./filename
# or, open in nano, control-o and then then alt-M a few times to toggle msdos format off and then save
#
set -x
#
#
# Install the packages we need for building
#
cd ~/Desktop
#
sudo apt -y install git
sudo apt -y install git-email
sudo apt -y install wget
sudo apt -y install valgrind lcov gcov
#
rm -fvR ./FFmpeg
git clone --depth 1 https://github.com/FFmpeg/FFmpeg.git ./FFmpeg

#if [[ ! -d ./FFmpeg ]]; then
#	git clone --depth 1 https://github.com/FFmpeg/FFmpeg.git ./FFmpeg
#fi
#
cd FFmpeg
#
# git fetch
#    updates your local repository with commits that have been added 
#    to the server since your last fetch
# git merge 
#     will try to combine two parallel development paths.
# They're completely different.
#
git pull --rebase
git reset --hard HEAD
git pull --rebase
git status
#
git config --global user.name "hydra3333"
git config --global user.email "hydra3333@gmail.com"
git config --global sendemail.smtpencryption tls
git config --global sendemail.smtpserver smtp.gmail.com
# 587 for TLS 465 for SSL
git config --global sendemail.smtpserverport 587
git config --global sendemail.smtpuser hydra3333@gmail.com
#git config --global sendemail.smtppass ?????
git config --unset sendemail.smtppass
git config --global --unset sendemail.smtppass
git config --global sendemail.to hydra3333@gmail.com
git config --global --list
git config --global credential.helper store
#
ls -al libavcodec/v4l2_m2m.h
rm -fv libavcodec/v4l2_m2m.h
#git rm libavcodec/v4l2_m2m.h
ls -al libavcodec/v4l2_m2m.h
wget --no-check-certificate https://raw.githubusercontent.com/hydra3333/FFmpeg/master/libavcodec/v4l2_m2m.h -O libavcodec/v4l2_m2m.h
touch libavcodec/v4l2_m2m.h
git add -v libavcodec/v4l2_m2m.h
ls -al libavcodec/v4l2_m2m.h
#
ls -al libavcodec/v4l2_m2m_enc.c
rm -fv libavcodec/v4l2_m2m_enc.c
#git rm libavcodec/v4l2_m2m_enc.c
ls -al libavcodec/v4l2_m2m_enc.c
wget --no-check-certificate https://raw.githubusercontent.com/hydra3333/FFmpeg/master/libavcodec/v4l2_m2m_enc.c -O libavcodec/v4l2_m2m_enc.c
touch libavcodec/v4l2_m2m_enc.c
git add -v libavcodec/v4l2_m2m_enc.c
ls -al libavcodec/v4l2_m2m_enc.c
#
git status
#
export GIT_AUTHOR_NAME="hydra3333"
export GIT_AUTHOR_EMAIL="hydra3333@gmail.com"
export GIT_COMMITTER_NAME="hydra3333"
export GIT_COMMITTER_EMAIL="hydra3333@gmail.com"
#
rm -fv "../ffmpeg_git_commit_message.txt"
cat >"../ffmpeg_git_commit_message.txt" <<EOF
Add and use cli options for v4l2 encoder=h264_v4l2m2m

Add commandline options to v4l2_m2m_enc (h264_v4l2m2m only)
and use those to configure options for the h264_v4l2m2m encoder.
Uses AVOption options to filter for valid options per v4l2 spec.
For h264 it adds spec-compliant:
-profile <name> (high is max accepted by Raspberry Pi)
-level <name>   (4.2 is max  accepted by Raspberry Pi)
-rc <name>      (Bitrate mode, VBR or CBR or CQ)
-shm <option>   (Sequence Header Mode, separate_buffer or joined_1st_frame)
-rsh <boolean>  (Repeat Sequence Header 0(false) 1(true))
-fsme           (Frame Skip Mode for encoder, rejected by Pi OS)
-b:v <bps>      (Bit per second)
-g <integer>    (pseudo GOP size, not an actual one)
-iframe_period <integer> (the period between two I-frames)
-qmin <integer> (Minimum quantization parameter for h264)
-qmax <integer> (Maximum quantization parameter for h264)

Patch does not address pre-existing quirks with h264_v4l2m2m,
eg on a Raspberry Pi,
- Bitrate mode VBR, file is reported by mediainfo as CBR
- Bitrate mode CBR, encoder hangs and appears to 
  "lock" /dev/video11 until reboot
- CFR input yields a VFR file reported by mediainfo (and an
  odd framerate) whereas an equivalent libx264 commandline
  yields expected CFR; tested on a Raspberry Pi4
- Bitrate mode CBR, profile is limited to less than "high"
- Bitrate mode VBR, only target bitrate option exposed to set
- Bitrate mode CQ, is not exposed to set

Notes:
Patch arises from a desire to use ffmpeg on a Raspberry Pi (4 +).
Fixes "--profile high" not working (required an integer).
The Raspberry Pi OS does not expose a GOP size to set, so -g is
used for backward compatibility with its value overriding
the "close enough" effect of an "iframe_period" value.
Hardware like Raspberry Pi 4 rejects some spec-compliant options
beyond its capacity and/or not implemented by the Raspberry Pi OS.
The Raspberry Pi OS repository for ffmpeg appears to have Repeat
Sequence Header hard-coded as True, rather than a cli an option.
Added more return value checking, AV_LOG_WARNING and a lot
more AV_LOG_DEBUG code; one-time runtime cost of debug code
during init phase is negligible.
Intentionally left in //commented-out debug code.

A working commandline using an interlaced source:
/usr/local/bin/ffmpeg -hide_banner -nostats -v debug \
-i "~/Desktop/input_file_tiny.mp4" \
-vsync cfr \
-sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp \
-strict experimental \
-filter_complex "[0:v]yadif=0:0:0,format=pix_fmts=yuv420p" \
-c:v h264_v4l2m2m \
-pix_fmt yuv420p \
-rc VBR \
-b:v 4000000 \
-qmin 10 -qmax 51 \
-profile:v high \
-level 4.2 \
-shm separate_buffer \
-rsh 0 \
-g:v 25 \
-movflags +faststart+write_colr \
-an \
-y "./output_file_tiny_h264_VBR_g25.mp4"
EOF
#
ls -al "../ffmpeg_git_commit_message.txt"
cat "../ffmpeg_git_commit_message.txt"
#
git commit --signoff --file="../ffmpeg_git_commit_message.txt"
git status
#
##git log --name-status HEAD^..HEAD
##git log -1 --pretty=format:"%H" # for the commit hash alone
##git log -1 --stat # to show the last commit USE THIS
##git show --name-status --oneline
##commit_id=$(git log -1 --pretty=format:"%H")
##echo "${commit_id}"

# get the DIFF for the last commit ready for emailing
rm -fv ../updated_v4l2m2m_options.patch
##git diff -patch HEAD^ HEAD --output=../updated_v4l2m2m_options.patch
##git show HEAD >../updated_v4l2m2m_options.patch
git format-patch -1 HEAD --signoff --stat --output=../updated_v4l2m2m_options.patch
#cat ../updated_v4l2m2m_options.patch
#
rm -fv ./updated_v4l2m2m_options.patch.eml
git format-patch -1 HEAD --signoff --stat --output=../updated_v4l2m2m_options.patch.eml --add-header "X-Unsent: 1" --to ffmpeg-devel@ffmpeg.org
#--to hydra3333@gmail.com
#cat ../updated_v4l2m2m_options.patch.eml
#
# 15H15
git send-email -1 --from=hydra3333@gmail.com --to=hydra3333@gmail.com 

read -p "Press ENTER to continue" x

echo "Build it for FATE ONLY using VALGRIND"
export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
./configure \
	--toolchain=valgrind-memcheck \
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
make -j$(nproc)		# for FATE ONLY using VALGRIND
sudo make install	# for FATE ONLY using VALGRIND
export -n CFLAGS
export -n CXXFLAGS
export -n CPPFLAGS
export -n LDFLAGS

#read -p "Press ENTER to continue to test 'make fate'" x


#echo "Try FATE tests with VALGRIND"
#make fate 2>&a | tee ./VALGRIND_output.txt

read -p "Press ENTER to continue to run a VALGRIND sample" x


echo "try a sample VFR encode with VALGRIND"
rm -fv ff_VBR_g25_VALGRIND.log
mediainfo -full "../some_test_input_file_tiny.mp4" 2>&1 >> ff_VBR_g25_VALGRIND.log
mediainfo -full "../some_test_input_file_tiny.mp4" 2>&1  > ff_VBR_g25_1_BEFORE_VALGRIND.log
/usr/local/bin/ffmpeg -hide_banner -nostats -v debug \
		-i "../some_test_input_file_tiny.mp4" \
		-vsync cfr \
		-sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp \
		-strict experimental \
		-filter_complex "[0:v]yadif=0:0:0,format=pix_fmts=yuv420p" \
		-c:v h264_v4l2m2m \
		-pix_fmt yuv420p \
		-rc VBR \
		-b:v 4000000 \
		-qmin 10 -qmax 51 \
		-profile:v high \
		-level 4.2 \
		-shm separate_buffer \
		-rsh 0 \
		-g:v 25 \
		-movflags +faststart+write_colr \
		-an \
		-y "./some_test_input_file_tiny_transcoded_h264_VBR_g25_v4l2m2m.mp4" 2>&1 | tee -a ff_VBR_g25_VALGRIND.log
mediainfo -full "./some_test_input_file_tiny_transcoded_h264_VBR_g25_v4l2m2m.mp4" 2>&1 >> ff_VBR_g25_VALGRIND.log
mediainfo -full "./some_test_input_file_tiny_transcoded_h264_VBR_g25_v4l2m2m.mp4" 2>&1  > ff_VBR_g25_2_AFTER_VALGRIND.log

#read -p "Press ENTER to continue" x

#echo "Now try the Coverage tool"
## Configure to compile with instrumentation enabled: 'configure --toolchain=gcov'
## Run your test case, either manually or via FATE. 
## This can be either the full FATE regression suite, or any arbitrary invocation of any front-end tool provided by FFmpeg, in any combination.
## Run 'make lcov' to generate coverage data in HTML format.
## View 'lcov/index.html' in your preferred HTML viewer.
## You can use the command 'make lcov-reset' to reset the coverage measurements. 
## You will need to rerun 'make lcov' after running a new test.
#export CFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
#export CXXFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
#export CPPFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
#export LDFLAGS=" -O3 -fstack-protector-all -D_FORTIFY_SOURCE=2 -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib "
#./configure \
#	--toolchain=--toolchain=gcov \
#	--extra-version="ffmpeg_for_RPi4B_having_h264_v4l2m2m" \
#	--arch=aarch64 --target-os=linux \
#	--disable-shared --enable-static --enable-pic --enable-neon --disable-w32threads --enable-pthreads \
#	--enable-gpl --enable-version3 --enable-nonfree \
#	--prefix=/usr/local \
#	--libdir=/usr/local/lib \
#	--bindir=/usr/local/bin \
#	--extra-cflags=" -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib " \
#	--extra-ldflags=" -I/usr/local/include -I/usr/include/aarch64-linux-gnu -I/usr/include -L/usr/local/lib -L/usr/lib/aarch64-linux-gnu -L/usr/lib " \
#	--extra-libs="-lpthread -lm -latomic" \
#	--pkg-config=pkg-config \
#	--pkg-config-flags=--static \
#	--disable-doc --disable-htmlpages --disable-manpages --disable-podpages --disable-txtpages \
#	--disable-avisynth \
#	--disable-vapoursynth \
#	--disable-libkvazaar \
#	--disable-schannel \
#	--enable-v4l2-m2m \
#	--enable-hardcoded-tables \
#	--enable-gray \
#	--enable-gmp \
#	--enable-gnutls \
#	--enable-iconv \
#	--enable-libaom \
#	--enable-libass \
#	--enable-libdav1d \
#	--enable-libdrm \
#	--enable-libfdk-aac \
#	--enable-libmp3lame \
#	--enable-libtwolame \
#	--enable-libfreetype \
#	--enable-libopencore-amrnb \
#	--enable-libopencore-amrwb \
#	--enable-libopus \
#	--enable-librtmp \
#	--enable-libsnappy \
#	--enable-libsoxr \
#	--enable-libssh \
#	--enable-libvorbis \
#	--enable-libvpx \
#	--enable-libzimg \
#	--enable-libwebp \
#	--enable-libx264 \
#	--enable-libx265 \
#	--enable-libxml2 \
#	--enable-librubberband \
#	--enable-libwebp \
#	--enable-zlib \
#	--enable-lzma \
#	--extra-cflags="-DLIBTWOLAME_STATIC" \
#	--extra-cflags="-DLIBXML_STATIC"
#make -j$(nproc)
#sudo make install
#export -n CFLAGS
#export -n CXXFLAGS
#export -n CPPFLAGS
#export -n LDFLAGS
#
#read -p "Press ENTER to continue" x
#
#echo "try a sample VFR encode with the coverage tool"
#rm -fv ./ff_VBR_g25_COVERAGE.log
#/usr/local/bin/ffmpeg -hide_banner -nostats -v debug \
#		-i "~/Desktop/some_test_input_file_tiny.mp4" \
#		-vsync cfr \
#		-sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp \
#		-strict experimental \
#		-filter_complex "[0:v]yadif=0:0:0,format=pix_fmts=yuv420p" \
#		-c:v h264_v4l2m2m \
#		-pix_fmt yuv420p \
#		-rc VBR \
#		-b:v 4000000 \
#		-qmin 10 -qmax 51 \
#		-profile:v high \
#		-level 4.2 \
#		-shm separate_buffer \
#		-rsh 0 \
#		-g:v 25 \
#		-movflags +faststart+write_colr \
#		-an \
#		-y "./some_test_input_file_tiny_transcoded_h264_VBR_g25_v4l2m2m.mp4" 2>&1 > ./ff_VBR_g25_COVERAGE.log
#
#echo "Run 'make lcov' to generate coverage data in HTML format."
#make lcov 2>&1 >> ./ff_VBR_g25_COVERAGE.log
#ls -al lcov/index.html 2>&1 >> ./ff_VBR_g25_COVERAGE.log
#echo "View 'lcov/index.html' in your preferred HTML viewer" 2>&1 >> ./ff_VBR_g25_COVERAGE.log
#

read -p "Press ENTER to continue" x

rm -fv /usr/local/bin/ffmpeg 

cd ~/Desktop
#

