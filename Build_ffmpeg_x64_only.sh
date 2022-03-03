#!/bin/bash
# to get rid of MSDOS format do this to this file: sudo sed -i s/\\r//g ./filename
# or, open in nano, control-o and then then alt-M a few times to toggle msdos format off and then save
#
#
# Build ffmpeg only, without (re)building dependencies
#
sh ./Build_ffmpeg_x64_for_Raspberry_Pi4_bullseye.sh "ffmpeg_only"
#
