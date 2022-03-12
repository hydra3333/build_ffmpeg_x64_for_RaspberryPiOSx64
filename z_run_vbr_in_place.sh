#!/bin/bash
# to get rid of MSDOS format do this to this file: sudo sed -i s/\\r//g ./filename
# or, open in nano, control-o and then then alt-M a few times to toggle msdos format off and then save
#
set -x
cd ~/Desktop


#rm -fv ff_VBR_std.log
#/usr/bin/ffmpeg -hide_banner -nostats -v debug \
#		-i "./some_test_input_file_tiny.mp4" \
#		-vsync cfr \
#		-sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp \
#		-strict experimental \
#		-filter_complex "[0:v]yadif=0:0:0,format=pix_fmts=yuv420p" \
#		-c:v h264_v4l2m2m \
#		-pix_fmt yuv420p \
#		-b:v 4000000 \
#		-profile:v 4 \
#		-level 4.2 \
#		-g:v 25 \
#		-movflags +faststart+write_colr \
#		-an \
#		-y "./some_test_input_file_tiny_transcoded_h264_VBR_std_v4l2m2m.mp4" 2>&1 | tee ff_VBR_std.log


echo "************************************************************************************************************************"

rm -fv ff_CBR.log
mediainfo -full "./some_test_input_file_tiny.mp4" 2>&1 >> ff_CBR.log
mediainfo -full "./some_test_input_file_tiny.mp4" 2>&1 > ff_CBR_1_BEFORE.log
/usr/local/bin/ffmpeg -hide_banner -nostats -v debug \
		-i "./some_test_input_file_tiny.mp4" \
		-vsync cfr \
		-sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp \
		-strict experimental \
		-filter_complex "[0:v]yadif=0:0:0,format=pix_fmts=yuv420p" \
		-c:v h264_v4l2m2m \
		-pix_fmt yuv420p \
		-rc CBR \
		-b:v 4000000 \
		-qmin 10 -qmax 51 \
		-profile:v high \
		-level 4.2 \
		-shm separate_buffer \
		-rsh 0 \
		-g:v 25 \
		-movflags +faststart+write_colr \
		-an \
		-y "./some_test_input_file_tiny_transcoded_h264_CBR_v4l2m2m.mp4" 2>&1 | tee ff_CBR.log

mediainfo -full "./some_test_input_file_tiny_transcoded_h264_CBR_v4l2m2m.mp4" 2>&1 >> ff_CBR.log
mediainfo -full "./some_test_input_file_tiny_transcoded_h264_CBR_v4l2m2m.mp4" 2>&1 > ff_CBR_2_AFTER.log
#/usr/local/bin/ffmpeg -hide_banner -encoders 2>&1 >> ff_CBR.log
#/usr/local/bin/ffmpeg -hide_banner -h encoder=h264_v4l2m2m 2>&1 >> ff_CBR.log
#/usr/local/bin/ffmpeg -hide_banner -h encoder=h264_v4l2m2m 2>&1 >> ff_CBR.log


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
		-y "./some_test_input_file_tiny_transcoded_h264_VBR_g25_v4l2m2m.mp4" 2>&1 | tee ff_VBR_g25.log

mediainfo -full "./some_test_input_file_tiny_transcoded_h264_VBR_g25_v4l2m2m.mp4" 2>&1 >> ff_VBR_g25.log
mediainfo -full "./some_test_input_file_tiny_transcoded_h264_VBR_g25_v4l2m2m.mp4" 2>&1 > ff_VBR_g25_2_AFTER.log
#/usr/local/bin/ffmpeg -hide_banner -encoders 2>&1 >> ff_VBR_g25.log
#/usr/local/bin/ffmpeg -hide_banner -h encoder=h264_v4l2m2m 2>&1 >> ff_VBR_g25.log
#/usr/local/bin/ffmpeg -hide_banner -h encoder=h264_v4l2m2m 2>&1 >> ff_VBR_g25.log


echo "************************************************************************************************************************"

#rm -fv ff_CQ_g25.log
#mediainfo -full "./some_test_input_file_tiny.mp4" 2>&1 >> ff_CQ_g25.log
#mediainfo -full "./some_test_input_file_tiny.mp4" 2>&1 > ff_CQ_g25_1_BEFORE.log
#/usr/local/bin/ffmpeg -hide_banner -nostats -v DEBUG \
#		-i "./some_test_input_file_tiny.mp4" \
#		-vsync cfr \
#		-sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp \
#		-strict experimental \
#		-filter_complex "[0:v]yadif=0:0:0,format=pix_fmts=yuv420p" \
#		-c:v h264_v4l2m2m \
#		-pix_fmt yuv420p \
#		-rc CQ \
#		-b:v 4000000 \
#		-qmin 10 -qmax 51 \
#		-profile:v high \
#		-level 4.2 \
#		-shm separate_buffer \
#		-rsh 0 \
#		-g:v 25 \
#		-movflags +faststart+write_colr \
#		-an \
#		-y "./some_test_input_file_tiny_transcoded_h264_CQ_g25_v4l2m2m.mp4" 2>&1 | tee ff_CQ_g25.log
#
#mediainfo -full "./some_test_input_file_tiny_transcoded_h264_CQ_g25_v4l2m2m.mp4" 2>&1 >> ff_CQ_g25.log
#mediainfo -full "./some_test_input_file_tiny_transcoded_h264_CQ_g25_v4l2m2m.mp4" 2>&1 > ff_CQ_g25_2_AFTER.log
#/usr/local/bin/ffmpeg -hide_banner -encoders 2>&1 >> ff_CQ_g25.log
#/usr/local/bin/ffmpeg -hide_banner -h encoder=h264_v4l2m2m 2>&1 >> ff_CQ_g25.log
#/usr/local/bin/ffmpeg -hide_banner -h encoder=h264_v4l2m2m 2>&1 >> ff_CQ_g25.log


echo "************************************************************************************************************************"


#		-g:v 25 \
#		-iframe_period 0
#		-iframe_period 25