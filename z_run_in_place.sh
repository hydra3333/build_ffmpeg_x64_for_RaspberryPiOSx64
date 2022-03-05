#!/bin/bash
# to get rid of MSDOS format do this to this file: sudo sed -i s/\\r//g ./filename
# or, open in nano, control-o and then then alt-M a few times to toggle msdos format off and then save
#
set -x
cd ~/Desktop

#rm -fv tee ff_libx264.log
#/usr/local/bin/ffmpeg -hide_banner -v trace \
#		-i "./some_test_input_file_tiny.mp4" \
#		-preset slow \
#		-probesize 200M -analyzeduration 200M  \
#		-filter_complex "[0:v]yadif=0:0:0,setdar=16/9,format=pix_fmts=yuv420p" \
#		-sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp  \
#		-strict experimental \
#		-c:v libx264  \
#		-preset slow \
#		-pix_fmt yuv420p \
#		-forced-idr 1 \
#		-g 25 \
#		-keyint_min 5 \
#		-coder:v cabac \
#		-bf:v 3 \
#		-crf -1 \
#		-b:v 4000000 \
#		-minrate:v 500000 \
#		-maxrate:v 5000000 \
#		-bufsize 5000000 \
#		-profile:v high \
#		-level 5.2 \
#		-movflags +faststart+write_colr \
#		-an \
#		-y "./some_test_input_file_tiny_transcoded_libx264.mp4" 2>&1 | tee ff_libx264.log

rm -fv tee ff_libx264.log
/usr/local/bin/ffmpeg -hide_banner -v debug \
		-i "./some_test_input_file_tiny.mp4" \
		-preset slow \
		-filter_complex "[0:v]yadif=0:0:0,format=pix_fmts=yuv420p" \
		-sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp  \
		-strict experimental \
		-c:v libx264  \
		-preset veryfast \
		-pix_fmt yuv420p \
		-g 25 \
		-b:v 4000000 -minrate:v 500000 -maxrate:v 5000000 -bufsize:v 5000000 \
		-profile:v high \
		-level 5.2 \
		-movflags +faststart+write_colr \
		-an \
		-y "./some_test_input_file_tiny_transcoded_libx264.mp4" 2>&1 | tee ff_libx264.log

rm -fv ff.log
/usr/local/bin/ffmpeg -hide_banner -nostats -v trace \
		-i "./some_test_input_file_tiny.mp4" \
		-vsync cfr \
		-sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp \
		-strict experimental \
		-filter_complex "[0:v]yadif=0:0:0,format=pix_fmts=yuv420p" \
		-c:v h264_v4l2m2m \
		-pix_fmt yuv420p \
		-b:v 4000000 -minrate:v 500000 -maxrate:v 5000000 -bufsize:v 5000000 \
		-profile:v high \
		-level 4.2 \
		-rc VBR \
		-shm separate_buffer \
		-rsh 0 \
		-iframe_period 25 \
		-movflags +faststart+write_colr \
		-an \
		-y "./some_test_input_file_tiny_transcoded_h264_v4l2m2m.mp4" 2>&1 | tee ff.log

#		-g:v 25 \

exit



#main10
rm -fv ff.log
/usr/local/bin/ffmpeg -hide_banner -nostats -v debug \
		-i "./some_test_input_file_tiny.mp4" \
		-vsync cfr \
		-sws_flags lanczos+accurate_rnd+full_chroma_int+full_chroma_inp \
		-strict experimental \
		-filter_complex "[0:v]yadif=0:0:0,format=pix_fmts=yuv420p" \
		-c:v h264_v4l2m2m -pix_fmt yuv420p \
		-g:v 25 \
		-keyint_min 5 \
		-b:v 4000000 -minrate:v 500000 -maxrate:v 5000000 -bufsize:v 5000000 \
		-profile:v main10 \
		-level 13 \
		-movflags +faststart+write_colr \
		-an \
		-y "./some_test_input_file_tiny_transcoded_h264_v4l2m2m.mp4" 2>&1 | tee ff.log

