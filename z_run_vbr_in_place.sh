#!/bin/bash
# to get rid of MSDOS format do this to this file: sudo sed -i s/\\r//g ./filename
# or, open in nano, control-o and then then alt-M a few times to toggle msdos format off and then save
#
set -x
cd ~/Desktop


rm -fv ff_std.log
mediainfo -full "./some_test_input_file_tiny.mp4" 2>&1 >> ff_std.log
mediainfo -full "./some_test_input_file_tiny.mp4" 2>&1 > ff_std_1_BEFORE.log
/usr/local/bin/ffmpeg -hide_banner -v debug \
		-i "./some_test_input_file_tiny.mp4" \
		-vsync cfr \
		-preset slow \
		-probesize 200M -analyzeduration 200M  \
		-filter_complex "[0:v]yadif=0:0:0,setdar=16/9,format=pix_fmts=yuv420p" \
		-sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp  \
		-strict experimental \
		-c:v libx264  \
		-preset slow \
		-pix_fmt yuv420p \
		-forced-idr 1 \
		-g 25 \
		-coder:v cabac \
		-bf:v 3 \
		-b:v 4000000 \
		-minrate:v 400000 \
		-maxrate:v 6000000 \
		-bufsize 6000000 \
		-profile:v high \
		-level 4.2 \
		-movflags +faststart+write_colr \
		-an \
		-y "./some_test_input_file_tiny_transcoded_h264_std.mp4" 2>&1 | tee -a ff_std.log

#		-qmin 10 -qmax 51 \
#		-keyint_min 5 \
#		-crf -1
mediainfo -full "./some_test_input_file_tiny_transcoded_h264_std.mp4" 2>&1 >> ff_std.log
mediainfo -full "./some_test_input_file_tiny_transcoded_h264_std.mp4" 2>&1 > ff_std_2_AFTER.log


echo "************************************************************************************************************************"

rm -fv ff_VBR_g25.log
mediainfo -full "./some_test_input_file_tiny.mp4" 2>&1 >> ff_VBR_g25.log
mediainfo -full "./some_test_input_file_tiny.mp4" 2>&1 > ff_VBR_g25_1_BEFORE.log
/usr/local/bin/ffmpeg -hide_banner -nostats -v debug \
		-i "./some_test_input_file_tiny.mp4" \
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
		-y "./some_test_input_file_tiny_transcoded_h264_VBR_g25_v4l2m2m.mp4" 2>&1 | tee -a ff_VBR_g25.log

mediainfo -full "./some_test_input_file_tiny_transcoded_h264_VBR_g25_v4l2m2m.mp4" 2>&1 >> ff_VBR_g25.log
mediainfo -full "./some_test_input_file_tiny_transcoded_h264_VBR_g25_v4l2m2m.mp4" 2>&1 > ff_VBR_g25_2_AFTER.log

#/usr/local/bin/ffmpeg -hide_banner -encoders 2>&1 >> ff_VBR_g25.log
#/usr/local/bin/ffmpeg -hide_banner -h encoder=h264_v4l2m2m 2>&1 >> ff_VBR_g25.log
#/usr/local/bin/ffmpeg -hide_banner -h encoder=h264_v4l2m2m 2>&1 >> ff_VBR_g25.log


echo "************************************************************************************************************************"

# CBR in case it crashes and locks video11

#rm -fv ff_CBR.log
#mediainfo -full "./some_test_input_file_tiny.mp4" 2>&1 >> ff_CBR.log
#mediainfo -full "./some_test_input_file_tiny.mp4" 2>&1 > ff_CBR_1_BEFORE.log
#/usr/local/bin/ffmpeg -hide_banner -nostats -v debug \
#		-i "./some_test_input_file_tiny.mp4" \
#		-vsync cfr \
#		-sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp \
#		-strict experimental \
#		-filter_complex "[0:v]yadif=0:0:0,format=pix_fmts=yuv420p" \
#		-c:v h264_v4l2m2m \
#		-pix_fmt yuv420p \
#		-rc CBR \
#		-b:v 4000000 \
#		-qmin 10 -qmax 51 \
#		-profile:v main \
#		-level 4 \
#		-shm separate_buffer \
#		-rsh 0 \
#		-g:v 25 \
#		-movflags +faststart+write_colr \
#		-an \
#		-y "./some_test_input_file_tiny_transcoded_h264_CBR_v4l2m2m.mp4" 2>&1 | tee -a ff_CBR.log
#
#mediainfo -full "./some_test_input_file_tiny_transcoded_h264_CBR_v4l2m2m.mp4" 2>&1 >> ff_CBR.log
#mediainfo -full "./some_test_input_file_tiny_transcoded_h264_CBR_v4l2m2m.mp4" 2>&1 > ff_CBR_2_AFTER.log
#/usr/local/bin/ffmpeg -hide_banner -encoders 2>&1 >> ff_CBR.log
#/usr/local/bin/ffmpeg -hide_banner -h encoder=h264_v4l2m2m 2>&1 >> ff_CBR.log
#/usr/local/bin/ffmpeg -hide_banner -h encoder=h264_v4l2m2m 2>&1 >> ff_CBR.log


echo "************************************************************************************************************************"