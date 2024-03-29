/**
 * V4L2 mem2mem encoders
 *
 * Copyright (C) 2017 Alexis Ballier <aballier@gentoo.org>
 * Copyright (C) 2017 Jorge Ramirez <jorge.ramirez-ortiz@linaro.org>
 *
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#include <linux/videodev2.h>
#include <sys/ioctl.h>
#include <search.h>
#include "encode.h"
#include "libavcodec/avcodec.h"
#include "libavutil/pixdesc.h"
#include "libavutil/pixfmt.h"
#include "libavutil/opt.h"
#include "codec_internal.h"
#include "profiles.h"
#include "v4l2_context.h"
#include "v4l2_m2m.h"
#include "v4l2_fmt.h"

#define MPEG_CID(x) V4L2_CID_MPEG_VIDEO_##x
#define MPEG_VIDEO(x) V4L2_MPEG_VIDEO_##x

static inline int v4l2_set_timeperframe(V4L2m2mContext *s, unsigned int num, unsigned int den)
{
    /**
       v4l2_streamparm, V4L2_TYPE_IS_MULTIPLANAR defined in linux/videodev2.h
     */
    struct v4l2_streamparm parm = { 0 };
    int ret;
    parm.type = V4L2_TYPE_IS_MULTIPLANAR(s->output.type) ? V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE : V4L2_BUF_TYPE_VIDEO_OUTPUT;
    parm.parm.output.timeperframe.denominator = den;
    parm.parm.output.timeperframe.numerator = num;
    av_log(s->avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m attempting to ioctl SET timeperframe; "
        "denominator='%d' numerator='%d'\n", den, num);
    ret = ioctl(s->fd, VIDIOC_S_PARM, &parm);
    if (ret < 0) {
        av_log(s->avctx, AV_LOG_ERROR, 
            "Encoder v4l2_m2m ERROR Failed to ioctl SET timeperframe; denominator='%d' numerator='%d' "
            "ret='%d' errno='%d' error='%s'\n", den, num, ret, errno, strerror(errno));
        return ret;
    }
    av_log(s->avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m ioctl SET timeperframe; "
        "denominator='%d' numerator='%d'\n", den, num);
    return 0;
}

static inline int v4l2_set_ext_ctrl(V4L2m2mContext *s, unsigned int id, signed int value, const char *name, int log_warning)
{
    struct v4l2_ext_controls ctrls = { { 0 } };
    struct v4l2_ext_control ctrl = { 0 };
    int ret;
    /* set ctrls */
    ctrls.ctrl_class = V4L2_CTRL_CLASS_MPEG;
    ctrls.controls = &ctrl;
    ctrls.count = 1;
    /* set ctrl*/
    ctrl.value = value;
    ctrl.id = id;

    av_log(s->avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m attempting to ioctl SET '%s'='%d'\n", name, value);
    ret = ioctl(s->fd, VIDIOC_S_EXT_CTRLS, &ctrls);
    if (ret < 0) {
        av_log(s->avctx, log_warning || errno != EINVAL ? AV_LOG_WARNING : AV_LOG_DEBUG,
               "Encoder v4l2_m2m WARNING Failed to ioctl SET '%s'='%d' "
               "ret='%d' errno='%d' warning='%s'\n", 
               name, value, ret, errno, strerror(errno));
    } else {
        av_log(s->avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m ioctl SET '%s'='%d'\n", name, value);
    }
    return ret;
}

static inline int v4l2_get_ext_ctrl(V4L2m2mContext *s, unsigned int id, signed int *value, const char *name, int log_warning)
{
    struct v4l2_ext_controls ctrls = { { 0 } };
    struct v4l2_ext_control ctrl = { 0 };
    int ret;
    /* set ctrls */
    ctrls.ctrl_class = V4L2_CTRL_CLASS_MPEG;
    ctrls.controls = &ctrl;
    ctrls.count = 1;
    /* set ctrl*/
    ctrl.id = id ;
    av_log(s->avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m attempting to ioctl GET '%s'\n", name);
    ret = ioctl(s->fd, VIDIOC_G_EXT_CTRLS, &ctrls);
    if (ret < 0) {
        av_log(s->avctx, log_warning || errno != EINVAL ? AV_LOG_WARNING : AV_LOG_DEBUG,
               "Encoder v4l2_m2m WARNING Failed to ioctl GET '%s' "
               "ret='%d' errno='%d' warning='%s'\n", name, ret, errno, strerror(errno));
        return ret;
    }
    *value = ctrl.value;
    av_log(s->avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m ioctl GET '%s'='%d'\n", name, ctrl.value);
    return 0;
}

static inline int ff_h264_profile_from_v4l2_h264_profile(int p)
{
    static const struct h264_profile  {
        int v4l2_val;
        int ffmpeg_val;
    /** 
       NOTE: V4L2_MPEG_VIDEO_H264_ profile constants from linux/v4l2_controls.h via linux/videodev2.h
     */
    } profile[] = {
        { V4L2_MPEG_VIDEO_H264_PROFILE_BASELINE,                FF_PROFILE_H264_BASELINE },
        { V4L2_MPEG_VIDEO_H264_PROFILE_CONSTRAINED_BASELINE,    FF_PROFILE_H264_CONSTRAINED_BASELINE },
        { V4L2_MPEG_VIDEO_H264_PROFILE_MAIN,                    FF_PROFILE_H264_MAIN },
        { V4L2_MPEG_VIDEO_H264_PROFILE_HIGH,                    FF_PROFILE_H264_HIGH },
	    { V4L2_MPEG_VIDEO_H264_PROFILE_HIGH_10,                 FF_PROFILE_H264_HIGH_10 },
	    { V4L2_MPEG_VIDEO_H264_PROFILE_HIGH_422,                FF_PROFILE_H264_HIGH_422 },
	    { V4L2_MPEG_VIDEO_H264_PROFILE_HIGH_444_PREDICTIVE,     FF_PROFILE_H264_HIGH_444_PREDICTIVE },
	    { V4L2_MPEG_VIDEO_H264_PROFILE_HIGH_10_INTRA,           FF_PROFILE_H264_HIGH_10_INTRA },
	    { V4L2_MPEG_VIDEO_H264_PROFILE_HIGH_422_INTRA,          FF_PROFILE_H264_HIGH_422_INTRA },
	    { V4L2_MPEG_VIDEO_H264_PROFILE_HIGH_444_INTRA,          FF_PROFILE_H264_HIGH_444 },     /* ? presumed match */
	    { V4L2_MPEG_VIDEO_H264_PROFILE_CAVLC_444_INTRA,         FF_PROFILE_H264_CAVLC_444 },    /* ? presumed match */
	    { V4L2_MPEG_VIDEO_H264_PROFILE_MULTIVIEW_HIGH,          FF_PROFILE_H264_MULTIVIEW_HIGH },
	    { V4L2_MPEG_VIDEO_H264_PROFILE_STEREO_HIGH,             FF_PROFILE_H264_STEREO_HIGH },
	    /**
           { V4L2_MPEG_VIDEO_H264_PROFILE_SCALABLE_BASELINE,       FF_PROFILE_H264_SCALABLE_BASELINE },
	       { V4L2_MPEG_VIDEO_H264_PROFILE_SCALABLE_HIGH,           FF_PROFILE_H264_SCALABLE_HIGH },
	       { V4L2_MPEG_VIDEO_H264_PROFILE_SCALABLE_HIGH_INTRA,     FF_PROFILE_H264_SCALABLE_HIGH_INTRA },
	       { V4L2_MPEG_VIDEO_H264_PROFILE_CONSTRAINED_HIGH,        FF_PROFILE_H264_CONSTRAINED_HIGH },
         */
    };
    int i;
    for (i = 0; i < FF_ARRAY_ELEMS(profile); i++) {
        if (profile[i].v4l2_val == p)
            return profile[i].ffmpeg_val;
    }
    return AVERROR(ENOENT);
}

static inline int ff_h264_level_from_v4l2_h264_level(int p)
{
    static const struct h264_level  {
        int v4l2_val;
        int ffmpeg_val;
    /**
       V4L2_MPEG_VIDEO_H264_ profile constants from linux/v4l2_controls.h via linux/videodev2.h
       NOTE: the table from libavcodec/h264_levels.c  (not .h so we cannot include anything) :-
        H.264 table A-1.
        static const H264LevelDescriptor h264_levels[] = {
            Name          MaxMBPS                   MaxBR              MinCR
             | level_idc     |       MaxFS            |    MaxCPB        | MaxMvsPer2Mb
             |     | cs3f    |         |  MaxDpbMbs   |       |  MaxVmvR |   |
           { "1",   10, 0,     1485,     99,    396,     64,    175,   64, 2,  0 },
           { "1b",  11, 1,     1485,     99,    396,    128,    350,   64, 2,  0 },
           { "1b",   9, 0,     1485,     99,    396,    128,    350,   64, 2,  0 },
           { "1.1", 11, 0,     3000,    396,    900,    192,    500,  128, 2,  0 },
           { "1.2", 12, 0,     6000,    396,   2376,    384,   1000,  128, 2,  0 },
           { "1.3", 13, 0,    11880,    396,   2376,    768,   2000,  128, 2,  0 },
           { "2",   20, 0,    11880,    396,   2376,   2000,   2000,  128, 2,  0 },
           { "2.1", 21, 0,    19800,    792,   4752,   4000,   4000,  256, 2,  0 },
           { "2.2", 22, 0,    20250,   1620,   8100,   4000,   4000,  256, 2,  0 },
           { "3",   30, 0,    40500,   1620,   8100,  10000,  10000,  256, 2, 32 },
           { "3.1", 31, 0,   108000,   3600,  18000,  14000,  14000,  512, 4, 16 },
           { "3.2", 32, 0,   216000,   5120,  20480,  20000,  20000,  512, 4, 16 },
           { "4",   40, 0,   245760,   8192,  32768,  20000,  25000,  512, 4, 16 },
           { "4.1", 41, 0,   245760,   8192,  32768,  50000,  62500,  512, 2, 16 },
           { "4.2", 42, 0,   522240,   8704,  34816,  50000,  62500,  512, 2, 16 },
           { "5",   50, 0,   589824,  22080, 110400, 135000, 135000,  512, 2, 16 },
           { "5.1", 51, 0,   983040,  36864, 184320, 240000, 240000,  512, 2, 16 },
           { "5.2", 52, 0,  2073600,  36864, 184320, 240000, 240000,  512, 2, 16 },
           { "6",   60, 0,  4177920, 139264, 696320, 240000, 240000, 8192, 2, 16 },
           { "6.1", 61, 0,  8355840, 139264, 696320, 480000, 480000, 8192, 2, 16 },
           { "6.2", 62, 0, 16711680, 139264, 696320, 800000, 800000, 8192, 2, 16 },
        };
        NOTE mediainfo uses Android.Media.MediaCodecProfileLevel anmd they are different :(
        https://developer.android.com/reference/android/media/MediaCodecInfo.CodecProfileLevel
     */
    } level[] = {
        /**
           hard-coded libx264 FF numbers since no .h currently has them
         */
        { V4L2_MPEG_VIDEO_H264_LEVEL_1_0, 10 },
        { V4L2_MPEG_VIDEO_H264_LEVEL_1B,  11 },
        { V4L2_MPEG_VIDEO_H264_LEVEL_1_1, 11 },
        { V4L2_MPEG_VIDEO_H264_LEVEL_1_2, 12 },
        { V4L2_MPEG_VIDEO_H264_LEVEL_1_3, 13 },
        { V4L2_MPEG_VIDEO_H264_LEVEL_2_0, 20 },
        { V4L2_MPEG_VIDEO_H264_LEVEL_2_1, 21 },
        { V4L2_MPEG_VIDEO_H264_LEVEL_2_2, 22 },
        { V4L2_MPEG_VIDEO_H264_LEVEL_3_0, 30 },
        { V4L2_MPEG_VIDEO_H264_LEVEL_3_1, 31 },
        { V4L2_MPEG_VIDEO_H264_LEVEL_3_2, 32 },
        { V4L2_MPEG_VIDEO_H264_LEVEL_4_0, 40 },
        { V4L2_MPEG_VIDEO_H264_LEVEL_4_1, 41 },
        { V4L2_MPEG_VIDEO_H264_LEVEL_4_2, 42 },
        { V4L2_MPEG_VIDEO_H264_LEVEL_5_0, 50 },
        { V4L2_MPEG_VIDEO_H264_LEVEL_5_1, 51 },
        { V4L2_MPEG_VIDEO_H264_LEVEL_5_2, 52 },
        { V4L2_MPEG_VIDEO_H264_LEVEL_6_0, 60 },
        { V4L2_MPEG_VIDEO_H264_LEVEL_6_1, 61 },
        { V4L2_MPEG_VIDEO_H264_LEVEL_6_2, 62 },
    };
    int i;
    for (i = 0; i < FF_ARRAY_ELEMS(level); i++) {
        if (level[i].v4l2_val == p)
            return level[i].ffmpeg_val;
    }
    return AVERROR(ENOENT);
}

static inline int v4l2_mpeg4_profile_from_ff(int p)
{
    static const struct mpeg4_profile {
        unsigned int ffmpeg_val;
        unsigned int v4l2_val;
    } profile[] = {
        { FF_PROFILE_MPEG4_ADVANCED_CODING, MPEG_VIDEO(MPEG4_PROFILE_ADVANCED_CODING_EFFICIENCY) },
        { FF_PROFILE_MPEG4_ADVANCED_SIMPLE, MPEG_VIDEO(MPEG4_PROFILE_ADVANCED_SIMPLE) },
        { FF_PROFILE_MPEG4_SIMPLE_SCALABLE, MPEG_VIDEO(MPEG4_PROFILE_SIMPLE_SCALABLE) },
        { FF_PROFILE_MPEG4_SIMPLE, MPEG_VIDEO(MPEG4_PROFILE_SIMPLE) },
        { FF_PROFILE_MPEG4_CORE, MPEG_VIDEO(MPEG4_PROFILE_CORE) },
    };
    int i;

    for (i = 0; i < FF_ARRAY_ELEMS(profile); i++) {
        if (profile[i].ffmpeg_val == p)
            return profile[i].v4l2_val;
    }
    return AVERROR(ENOENT);
}

static int v4l2_check_b_frame_support(V4L2m2mContext *s)
{
    av_log(s->avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m attempting v4l2_check_b_frame_support "
        "attempting to ioctl GET number of b-frames\n");
    /**  
       https://github.com/raspberrypi/linux/issues/4917#issuecomment-1058120137
       B frames are not supported, and only 1 reference frame is ever used.
     */
    if (s->avctx->max_b_frames)
        av_log(s->avctx, AV_LOG_WARNING, "Encoder v4l2_m2m WARNING does not support b-frames for V4L2 encoding\n");
    v4l2_set_ext_ctrl(s, MPEG_CID(B_FRAMES), 0, "number of B-frames", 1);
    v4l2_get_ext_ctrl(s, MPEG_CID(B_FRAMES), &s->avctx->max_b_frames, "number of B-frames", 1);
    if (s->avctx->max_b_frames == 0) {
        return 0;
    }
    /* ??? was: avpriv_report_missing_feature(s->avctx, "Encoder DTS/PTS calculation for V4L2 encoding"); */
    avpriv_report_missing_feature(s->avctx, "Encoder v4l2_m2m does not support b-frames for V4L2 encoding\n");
    return AVERROR_PATCHWELCOME;
}

static int v4l2_subscribe_eos_event(V4L2m2mContext *s)
{
    struct v4l2_event_subscription sub;
    int ret;
    av_log(s->avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m v4l2_subscribe_eos_event attempting to "
        "ioctl VIDIOC_SUBSCRIBE_EVENT\n");
    memset(&sub, 0, sizeof(sub));
    sub.type = V4L2_EVENT_EOS;
    ret = (ioctl(s->fd, VIDIOC_SUBSCRIBE_EVENT, &sub));
    if (ret < 0) {
        av_log(s->avctx, AV_LOG_ERROR,
            "Encoder v4l2_m2m the v4l2 driver does not support end of stream VIDIOC_SUBSCRIBE_EVENT\n");
        return ret;
    }
    return 0;
}

static int v4l2_prepare_encoder(V4L2m2mContext *s)
{
    AVCodecContext *avctx = s->avctx;
    V4L2m2mPriv *priv = avctx->priv_data;  /* for per-codec private options; eg h264_profile etc when h264 */
    int qmin_cid, qmax_cid, qmin, qmax;
    int ret, val, ival;
    /**
     * requirements
     */
    ret = v4l2_subscribe_eos_event(s);
    if (ret) {
        av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR failed to v4l2_subscribe_eos_event, "
            "return code ret=(%d) errno=(%d) error='%s'\n", 
            ret, errno, strerror(errno));
        return AVERROR(EINVAL);
    }
    /** 
       https://github.com/raspberrypi/linux/issues/4917#issuecomment-1058120137
       B frames are not supported, and only 1 reference frame is ever used.
     */
    ret = v4l2_check_b_frame_support(s);
    if (ret) {
        av_log(avctx, AV_LOG_WARNING, "Encoder v4l2_m2m WARNING this encoder does not support b-frames") ;
        ///return ret;
    }
    av_log(s->avctx, AV_LOG_WARNING, "Encoder v4l2_m2m WARNING some hardware encoders do not support "
        "Frame Level Rate Control for V4L2 encoding; FLRC ignored.\n");
    /*
    ret = v4l2_set_ext_ctrl(s, MPEG_CID(FRAME_RC_ENABLE), 0, 
            "frame level rate control", 1); /// 1=enable, 0=disable; always disable(0)
    if (ret) {
        av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m failed to globally disable frame level rate "
            "control is OK. ret=(%d) errno=(%d) error='%s'\n", ret, errno, strerror(errno));
        ///return AVERROR(EINVAL);
    }
    */
    /**
       Codec-specific processing, eg h264, mpeg4, hevc(hevc), h263, vp8.
       Code is repeated but not always identical in each block, to ensure flexibility
       at the expense of dupication and elegance; some people don't like that.
     */
    switch (avctx->codec_id) {
    case AV_CODEC_ID_H264:
        /** 
           By now, the h264-specific profile and level and mode have been automatically 
           translated via Option values into h264 numeric values understood by the driver.
           see h264-specific options
           Back-fill some context with FFmpeg constant values, 
           to be compatible with previous version of encoder
         */
        val = ff_h264_profile_from_v4l2_h264_profile(priv->h264_profile);
        if (val < 0) {
            av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR profile not translated to FF-h264: "
                "profile not found (%d)\n",priv->h264_profile);
            return AVERROR(EINVAL);
        } else {
            avctx->profile = val;
        }
        val = ff_h264_level_from_v4l2_h264_level(priv->h264_level);
        if (val < 0) {
            av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR level not translated to H.264 table A-1: "
                "level not found (%d)\n",priv->h264_level);
            return AVERROR(EINVAL);
        } else {
            avctx->level = val;
        }
        if (priv->h264_video_bit_rate_mode == V4L2_MPEG_VIDEO_BITRATE_MODE_CBR &&
             priv->h264_profile == V4L2_MPEG_VIDEO_H264_PROFILE_HIGH) {
            av_log(avctx, AV_LOG_WARNING, "Encoder v4l2_m2m WARNING h264_video_bit_rate_mode 'CBR' "
                "and profile 'high' may not be compatible. Try profile 'main' if it fails.\n");
            ///return AVERROR(EINVAL);
        }
        if (priv->h264_qmin > priv->h264_qmax) {
            av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR (h264_only) priv->h264_qmin:(%d) "
                "must be <= h264_qmax (%d)\n", priv->h264_qmin, priv->h264_qmax);
            return AVERROR(EINVAL);
        }
        if (priv->h264_gop_size > 0) {
            priv->h264_iframe_period = priv->h264_gop_size;
        } else { /* fill in missing gop with h264_iframe_period which has a valid default */
            if (priv->h264_iframe_period >=0 ) {
                    priv->h264_gop_size = priv->h264_iframe_period;
            }
        }
        avctx->gop_size = priv->h264_gop_size;
        avctx->bit_rate = priv->h264_video_bit_rate;
        avctx->qmin = priv->h264_qmin;
        avctx->qmax = priv->h264_qmax;
        /* Show retrieved Option values */
	    av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m (global) codec_id:(%d)\n", avctx->codec_id);
        av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m (h264_only) priv->h264_profile:(%d)\n", priv->h264_profile);
        av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m (h264_only) priv->h264_level:(%d)\n", priv->h264_level);
        av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m (global) max_b_frames:(%d)\n", avctx->max_b_frames);
        if (avctx->framerate.num || avctx->framerate.den) {
            av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m (global) framerate.den:(%d)\n", avctx->framerate.den);
            av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m (global) framerate.num:(%d)\n", avctx->framerate.num);
            av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m (global) framerate.num:(%d/%d)\n", avctx->framerate.num, 
                avctx->framerate.den);
        }
        av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m (h264_only) priv->h264_video_bit_rate_mode:(%d) "
            "is one of VBR(%d) CBR(%d) CQ(%d)\n", 
            priv->h264_video_bit_rate_mode, 
            V4L2_MPEG_VIDEO_BITRATE_MODE_VBR, V4L2_MPEG_VIDEO_BITRATE_MODE_CBR, V4L2_MPEG_VIDEO_BITRATE_MODE_CQ);
        av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m (h264_only) priv->h264_video_bit_rate:(%"PRId64")\n", priv->h264_video_bit_rate);
        av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m (h264_only) priv->h264_qmin:(%d)\n", priv->h264_qmin);
        av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m (h264_only) priv->h264_qmax:(%d)\n", priv->h264_qmax);
        av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m (h264_only) priv->h264_sequence_header_mode:(%d)\n", priv->h264_sequence_header_mode);
        av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m (h264_only) priv->h264_repeat_seq_header:(%d)\n", priv->h264_repeat_seq_header);
        av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m (h264_only) priv->h264_iframe_period:(%d)\n", priv->h264_iframe_period);
        av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m (h264_only) priv->h264_gop_size:(%d)\n", priv->h264_gop_size);
        if (avctx->framerate.num || avctx->framerate.den) {
            av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m attempting to set timeperframe (%d/%d)\n", 
                avctx->framerate.num, avctx->framerate.den);
            ret = v4l2_set_timeperframe(s, avctx->framerate.den, avctx->framerate.num);
            if (ret) {
                av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR Failed to set timeperframe (%d/%d) "
                    "ret=(%d) errno=(%d) error='%s'\n", 
                    avctx->framerate.num, avctx->framerate.den, ret, errno, strerror(errno));
                return errno;
            } else {
                av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m successfully set timeperframe (%d/%d)\n",
                    avctx->framerate.num, avctx->framerate.den);
            }
        }        
        ret = v4l2_set_ext_ctrl(s, MPEG_CID(H264_PROFILE), priv->h264_profile, "h264 profile", 1);
        if (ret) {
            av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR failed to set h264_profile "
                "(%d) ret=(%d) errno=(%d) error='%s'\n'high' is possibly the max h264 profile on this hardware\n", 
                priv->h264_profile, ret, errno, strerror(errno));
            return AVERROR(EINVAL);
        }
        ret = v4l2_set_ext_ctrl(s, MPEG_CID(H264_LEVEL), priv->h264_level, "h264 Level", 1);
        if (ret) {
            av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR failed to set h264_level (%d) "
                "ret=(%d) errno=(%d) error='%s'\n'4.2' is possibly the max h264 level on this hardware\n", 
                priv->h264_level, ret, errno, strerror(errno));
            return AVERROR(EINVAL);
        }
        ret = v4l2_set_ext_ctrl(s, MPEG_CID(BITRATE_MODE), priv->h264_video_bit_rate_mode, 
            "h264 Bitrate Mode, VBR(0) or CBR(1) or CQ(2)", 1);
        if (ret) {
            av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR failed to set h264_video_bit_rate_mode (%d); "
                "VBR=(%d) CBR=(%d) CQ=(%d) ret=(%d) errno=(%d) error='%s'\n", 
                priv->h264_video_bit_rate_mode, 
                V4L2_MPEG_VIDEO_BITRATE_MODE_VBR, V4L2_MPEG_VIDEO_BITRATE_MODE_CBR, V4L2_MPEG_VIDEO_BITRATE_MODE_CQ, 
                ret, errno, strerror(errno));
            return AVERROR(EINVAL);
        }
        /* cast to int64_t to (int) used by v4l2_set_ext_ctrl */
        ret = v4l2_set_ext_ctrl(s, MPEG_CID(BITRATE), (int) priv->h264_video_bit_rate, "h264 Video Bitrate", 1);
        if (ret) {
            av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR failed to set h264_video_bit_rate (%"PRId64") "
                "ret=(%d) errno=(%d) error='%s'\n", priv->h264_video_bit_rate, ret, errno, strerror(errno));
            return AVERROR(EINVAL);
        }
        /**
           V4L2_CID_MPEG_VIDEO_FRAME_SKIP_MODE 
           Indicates in what conditions the encoder should skip frames. 
           If encoding a frame would cause the encoded stream to be larger than
           a chosen data limit then the frame will be skipped.
           V4L2_MPEG_VIDEO_FRAME_SKIP_MODE_DISABLED Frame skip mode is disabled.
         */
        if (priv->h264_frame_skip_mode_encoder != V4L2_MPEG_VIDEO_FRAME_SKIP_MODE_DISABLED) {
             av_log(avctx, AV_LOG_WARNING, "Encoder v4l2_m2m WARNING "
                "frame skip mode for encoder set to NON-disabled (%d)\n", 
                priv->h264_frame_skip_mode_encoder);
        } else {
             av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m "
                "frame skip mode for encoder set to disabled (%d)\n", 
                priv->h264_frame_skip_mode_encoder);
        }
        ret = v4l2_set_ext_ctrl(s, MPEG_CID(FRAME_SKIP_MODE), priv->h264_frame_skip_mode_encoder,
            "frame skip mode for encoder", 1);
        if (ret) {
            av_log(avctx, AV_LOG_WARNING, "Encoder v4l2_m2m WARNING failed to set "
                "frame skip mode for encoder (%d); ret=(%d) errno=(%d) error='%s'\n", 
                priv->h264_frame_skip_mode_encoder, ret, errno, strerror(errno));
            ///return AVERROR(EINVAL);
        }
        ret = v4l2_set_ext_ctrl(s, MPEG_CID(HEADER_MODE), priv->h264_sequence_header_mode, 
                "sequence header mode", 1);
        if (ret) {
            av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR failed to set h264_sequence_header_mode (%d) "
                "ret=(%d) errno=(%d) error='%s'\n", 
                priv->h264_sequence_header_mode, ret, errno, strerror(errno));
            return AVERROR(EINVAL);
        }        
        ret = v4l2_set_ext_ctrl(s, MPEG_CID(REPEAT_SEQ_HEADER), priv->h264_repeat_seq_header, 
                "repeat sequence header", 1); /* RPi repositories build with 1(True) */
        if (ret) {
            av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR failed to set h264_repeat_seq_header (%d) "
                "ret=(%d) errno=(%d) error='%s'\n", 
                priv->h264_repeat_seq_header, ret, errno, strerror(errno));
            return AVERROR(EINVAL);
        }
        /**
           h264_iframe_period instead of gop size per 
           https://github.com/raspberrypi/linux/issues/4917#issuecomment-1057977916
         */
        if (priv->h264_iframe_period >=0) {
            ret = v4l2_set_ext_ctrl(s, MPEG_CID(H264_I_PERIOD), priv->h264_iframe_period, 
                    "Period between I-frames", 1);
            if (ret) {
                av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR failed to set h264_iframe_period(/gop) (%d) "
                    "ret=(%d) errno=(%d) error='%s'\n", 
                    priv->h264_iframe_period, ret, errno, strerror(errno));
                return AVERROR(EINVAL);
            }
        } else {
            av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR h264_iframe_period(/gop) "
                "defaulted to not set (%d)\n", 
                priv->h264_iframe_period);
        }
        ret = v4l2_set_ext_ctrl(s, MPEG_CID(GOP_SIZE), avctx->gop_size, "h264 gop size", 1);
        if (ret) {
            av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m WARNING failed to set h264_gop_size (%d) "
                "is OK (not used by driver anyway) ret=(%d) errno=(%d) error='%s'\n", 
                priv->h264_gop_size, ret, errno, strerror(errno));
            ///return AVERROR(EINVAL);
        }
        ret = v4l2_set_ext_ctrl(s, MPEG_CID(H264_MIN_QP), priv->h264_qmin, "h264 Qmin", 1);
        if (ret) {
            av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m ERROR failed to set h264_qmin (%d) "
                "ret=(%d) errno=(%d) error='%s'\n", 
                priv->h264_qmin, ret, errno, strerror(errno));
            return AVERROR(EINVAL);
        }
        ret = v4l2_set_ext_ctrl(s, MPEG_CID(H264_MAX_QP), priv->h264_qmax, "h264 Qmax", 1);
        if (ret) {
            av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m ERROR failed to set h264_qmax (%d) "
                "ret=(%d) errno=(%d) error='%s'\n", 
                priv->h264_qmax, ret, errno, strerror(errno));
            return AVERROR(EINVAL);
        }
        break;
    case AV_CODEC_ID_MPEG4:
        if (avctx->framerate.num || avctx->framerate.den) {
            av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m attempting to set timeperframe (%d/%d)\n", 
                avctx->framerate.num, avctx->framerate.den);
            ret = v4l2_set_timeperframe(s, avctx->framerate.den, avctx->framerate.num);
            if (ret) {
                av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR Failed to set timeperframe (%d/%d) "
                    "val=(%d) errno=(%d) error='%s'\n", 
                    avctx->framerate.num, avctx->framerate.den, val, errno, strerror(errno));
                return errno;
            } else {
                av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m successfully set timeperframe (%d/%d)\n",
                    avctx->framerate.num, avctx->framerate.den);
            }
        } 
        if (avctx->profile != FF_PROFILE_UNKNOWN) {
            ival = v4l2_mpeg4_profile_from_ff(avctx->profile);
            if (ival < 0) {
                av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR mpeg4 profile not found/translated "
                    "from FF to V42L profile; FF=(%d)\n", avctx->profile);
                return AVERROR(EINVAL);
            } else {
                ret = v4l2_set_ext_ctrl(s, MPEG_CID(MPEG4_PROFILE), ival, "mpeg4 profile", 1);
                if (ret) {
                    av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR Failed to set mpeg4 V42L profile (%d) "
                        "ret=(%d) errno=(%d) error='%s'\n", 
                        ival, ret, errno, strerror(errno));
                    return errno;
                } else {
                    av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m successfully set mpeg4 profile (%d)\n", ival);
                }
            }
        }
        if (avctx->flags & AV_CODEC_FLAG_QPEL) {
            ret = v4l2_set_ext_ctrl(s, MPEG_CID(MPEG4_QPEL), 1, "mpeg4 qpel", 1); /* hard-code 1 as ON */
            if (ret) {
                av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR failed to set mpeg4_qpel to 1 "
                    "ret=(%d) errno=(%d) error='%s'\n",
                    ret, errno, strerror(errno));
                return AVERROR(EINVAL);
            }
        } else {
            av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m  mpeg4_qpel flag not specified, ignored");
        }
        qmin_cid = MPEG_CID(MPEG4_MIN_QP);
        qmax_cid = MPEG_CID(MPEG4_MAX_QP);
        qmin = 1;
        qmax = 31;
        break;
    case AV_CODEC_ID_HEVC:
        if (avctx->framerate.num || avctx->framerate.den) {
            av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m attempting to set timeperframe (%d/%d)\n", 
                avctx->framerate.num, avctx->framerate.den);
            ret = v4l2_set_timeperframe(s, avctx->framerate.den, avctx->framerate.num);
            if (ret) {
                av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR Failed to set timeperframe (%d/%d) "
                    "ret=(%d) errno=(%d) error='%s'\n", 
                    avctx->framerate.num, avctx->framerate.den, ret, errno, strerror(errno));
                return errno;
            } else {
                av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m successfully set timeperframe (%d/%d)\n",
                    avctx->framerate.num, avctx->framerate.den);
            }
        } 
        /* no qmin/qmax processing for HEVC */
        break;
    case AV_CODEC_ID_H263:
        if (avctx->framerate.num || avctx->framerate.den) {
            av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m attempting to set timeperframe (%d/%d)\n", 
                avctx->framerate.num, avctx->framerate.den);
            ret = v4l2_set_timeperframe(s, avctx->framerate.den, avctx->framerate.num);
            if (ret) {
                av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR Failed to set timeperframe (%d/%d) "
                    "ret=(%d) errno=(%d) error='%s'\n", 
                    avctx->framerate.num, avctx->framerate.den, ret, errno, strerror(errno));
                return errno;
            } else {
                av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m successfully set timeperframe (%d/%d)\n",
                    avctx->framerate.num, avctx->framerate.den);
            }
        } 
        qmin_cid = MPEG_CID(H263_MIN_QP);
        qmax_cid = MPEG_CID(H263_MAX_QP);
        qmin = 1;
        qmax = 31;
        break;
    case AV_CODEC_ID_VP8:
        if (avctx->framerate.num || avctx->framerate.den) {
            av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m attempting to set timeperframe (%d/%d)\n", 
                avctx->framerate.num, avctx->framerate.den);
            ret = v4l2_set_timeperframe(s, avctx->framerate.den, avctx->framerate.num);
            if (ret) {
                av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR Failed to set timeperframe (%d/%d) "
                    "ret=(%d) errno=(%d) error='%s'\n", 
                    avctx->framerate.num, avctx->framerate.den, ret, errno, strerror(errno));
                return errno;
            } else {
                av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m successfully set timeperframe (%d/%d)\n",
                    avctx->framerate.num, avctx->framerate.den);
            }
        } 
        qmin_cid = MPEG_CID(VPX_MIN_QP);
        qmax_cid = MPEG_CID(VPX_MAX_QP);
        qmin = 0;
        qmax = 127;
        break;
    case AV_CODEC_ID_VP9:
        if (avctx->framerate.num || avctx->framerate.den) {
            av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m attempting to set timeperframe (%d/%d)\n", 
                avctx->framerate.num, avctx->framerate.den);
            ret = v4l2_set_timeperframe(s, avctx->framerate.den, avctx->framerate.num);
            if (ret) {
                av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR Failed to set timeperframe (%d/%d) "
                    "ret=(%d) errno=(%d) error='%s'\n", 
                    avctx->framerate.num, avctx->framerate.den, ret, errno, strerror(errno));
                return errno;
            } else {
                av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m successfully set timeperframe (%d/%d)\n",
                    avctx->framerate.num, avctx->framerate.den);
            }
        } 
        qmin_cid = MPEG_CID(VPX_MIN_QP);
        qmax_cid = MPEG_CID(VPX_MAX_QP);
        qmin = 0;
        qmax = 255;
        break;
    default:
        av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR UNRECOGNISED CODEC ID (%d)\n", avctx->codec_id);
        return AVERROR(EINVAL);
    }

    if ( /* common qmin/qmax does not apply to H264 (own processing) nor HEVC (per legacy code) */
         avctx->codec_id == AV_CODEC_ID_MPEG4 ||
         avctx->codec_id == AV_CODEC_ID_H263 ||
         avctx->codec_id == AV_CODEC_ID_VP8 ||
         avctx->codec_id == AV_CODEC_ID_VP9
       ) {
        if (avctx->qmin >= 0 && avctx->qmax >= 0 && avctx->qmin > avctx->qmax) {
            av_log(avctx, AV_LOG_WARNING, "Invalid qmin:%d qmax:%d. qmin should not "
                                        "exceed qmax\n", avctx->qmin, avctx->qmax);
        } else {
            qmin = avctx->qmin >= 0 ? avctx->qmin : qmin;
            qmax = avctx->qmax >= 0 ? avctx->qmax : qmax;
        }
        ret = v4l2_set_ext_ctrl(s, qmin_cid, qmin, "minimum video quantizer scale",
                        avctx->qmin >= 0);
        if (ret) {
            av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m ERROR failed to set qmin (%d) "
                "ret=(%d) errno=(%d) error='%s'\n", 
                qmin, ret, errno, strerror(errno));
            return AVERROR(EINVAL);
        }
        ret = v4l2_set_ext_ctrl(s, qmax_cid, qmax, "maximum video quantizer scale",
                        avctx->qmax >= 0);
        if (ret) {
            av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m ERROR failed to set qmax (%d) "
                "ret=(%d) errno=(%d) error='%s'\n", 
                qmax, ret, errno, strerror(errno));
            return AVERROR(EINVAL);
        }
    }
    return 0;
}

static int v4l2_send_frame(AVCodecContext *avctx, const AVFrame *frame)
{
    int ret;

    V4L2m2mContext *s = ((V4L2m2mPriv*)avctx->priv_data)->context;
    V4L2Context *const output = &s->output;
    static const int Force_a_key_frame_for_the_next_queued_buffer = 0; /* not force for the next queued buffer */
#ifdef V4L2_CID_MPEG_VIDEO_FORCE_KEY_FRAME
    /**
       https://www.kernel.org/doc/html/latest/userspace-api/media/v4l/ext-ctrls-codec.html
       V4L2_CID_MPEG_VIDEO_FORCE_KEY_FRAME (button)
       When 1, Force a key frame for the next queued buffer.
       When 0, do not Force a key frame for the next queued buffer.
     */
    if (frame && frame->pict_type == AV_PICTURE_TYPE_I) {
        ret = v4l2_set_ext_ctrl(s, MPEG_CID(FORCE_KEY_FRAME), Force_a_key_frame_for_the_next_queued_buffer, 
                  "force key frame (0=no, 1=yes)", 1);
        if (ret) {
            /*
            av_log(avctx, AV_LOG_WARNING, "Encoder v4l2_m2m V4L2_CID_MPEG_VIDEO_FORCE_KEY_FRAME is defined, "
               "am processing an IFRAME, FAILED SET force a key frame for the next queued buffer as (0=off 1=on): %d "
               "ret=(%d) errno=(%d) error='%s'\n", 
               Force_a_key_frame_for_the_next_queued_buffer, ret, errno, strerror(errno));
            ///return AVERROR(EINVAL);
            */
        } else {
            /* 
            av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m V4L2_CID_MPEG_VIDEO_FORCE_KEY_FRAME is defined, "
            "am processing an IFRAME, successful SET force a key frame for the next queued buffer as (0=off 1=on): %d\n",
            Force_a_key_frame_for_the_next_queued_buffer);
            */
        }
    } else {
        /*
        av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m V4L2_CID_MPEG_VIDEO_FORCE_KEY_FRAME is defined, "
            "am NOT processing an IFRAME, hence did not set FORCE_KEY_FRAME for the next queued buffer\n");
        */
    }
#endif
#ifndef V4L2_CID_MPEG_VIDEO_FORCE_KEY_FRAME
    /*
    av_log(avctx, AV_LOG_DEBUG, "Encoder v4l2_m2m V4L2_CID_MPEG_VIDEO_FORCE_KEY_FRAME is not defined "
           "... so NOT forcing a key frame for the next queued buffer even if we wanted to.\n");
    */
#endif
    return ff_v4l2_context_enqueue_frame(output, frame);
}

static int v4l2_receive_packet(AVCodecContext *avctx, AVPacket *avpkt)
{
    V4L2m2mContext *s = ((V4L2m2mPriv*)avctx->priv_data)->context;
    V4L2Context *const capture = &s->capture;
    V4L2Context *const output = &s->output;
    AVFrame *frame = s->frame;
    int ret;
    if (s->draining)
        goto dequeue;

    if (!frame->buf[0]) {
        ret = ff_encode_get_frame(avctx, frame);
        if (ret < 0 && ret != AVERROR_EOF) {
            return ret;
        }
        if (ret == AVERROR_EOF) {
            frame = NULL;
        }
    }

    ret = v4l2_send_frame(avctx, frame);
    if (ret != AVERROR(EAGAIN)) {
        av_frame_unref(frame);
    }
    if (ret < 0 && ret != AVERROR(EAGAIN)) {
        return ret;
    }

    if (!output->streamon) {
        ret = ff_v4l2_context_set_status(output, VIDIOC_STREAMON);
        if (ret) {
            av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR VIDIOC_STREAMON failed on "
                "output context ret=(%d) errno=(%d) error='%s'\n",
                ret, errno, strerror(errno));
            return ret;
        }
    }

    if (!capture->streamon) {
        ret = ff_v4l2_context_set_status(capture, VIDIOC_STREAMON);
        if (ret) {
            av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m v4l2_receive_packet "
                "ERROR: VIDIOC_STREAMON failed on capture context "
                "ret=(%d) errno=(%d) error='%s'\n",
                ret, errno, strerror(errno));
            return ret;
        }
    }

dequeue:
    return ff_v4l2_context_dequeue_packet(capture, avpkt);
}

static av_cold int v4l2_encode_init(AVCodecContext *avctx)
{
    V4L2Context *capture, *output;
    V4L2m2mContext *s;
    V4L2m2mPriv *priv = avctx->priv_data;
    enum AVPixelFormat pix_fmt_output;
    uint32_t v4l2_fmt_output;
    int ret;
    ret = ff_v4l2_m2m_create_context(priv, &s);
    if (ret < 0) {
        av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m v4l2_encode_init ERROR ff_v4l2_m2m_create_context failed "
            "ret=(%d) errno=(%d) error='%s'\n",
            ret, errno, strerror(errno));
        return ret;
    }
    capture = &s->capture;
    output  = &s->output;

    /* common settings output/capture */
    output->height = capture->height = avctx->height;
    output->width = capture->width = avctx->width;

    /* output context */
    output->av_codec_id = AV_CODEC_ID_RAWVIDEO;
    output->av_pix_fmt = avctx->pix_fmt;

    /* capture context */
    capture->av_codec_id = avctx->codec_id;
    capture->av_pix_fmt = AV_PIX_FMT_NONE;

    s->avctx = avctx;
    ret = ff_v4l2_m2m_codec_init(priv);
    if (ret) {
        av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m v4l2_encode_init ERROR can't configure encoder "
            "ret=(%d) errno=(%d) error='%s'\n",
            ret, errno, strerror(errno));
        return ret;
    }

    if (V4L2_TYPE_IS_MULTIPLANAR(output->type))
        v4l2_fmt_output = output->format.fmt.pix_mp.pixelformat;
    else
        v4l2_fmt_output = output->format.fmt.pix.pixelformat;

    pix_fmt_output = ff_v4l2_format_v4l2_to_avfmt(v4l2_fmt_output, AV_CODEC_ID_RAWVIDEO);
    if (pix_fmt_output != avctx->pix_fmt) {
        const AVPixFmtDescriptor *desc = av_pix_fmt_desc_get(pix_fmt_output);
        av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m ERROR requires %s pixel format. "
            "ret=(%d) errno=(%d) error='%s'\n",
            desc->name, ret, errno, strerror(errno));
        return AVERROR(EINVAL);
    }
    return v4l2_prepare_encoder(s);
}

static av_cold int v4l2_encode_close(AVCodecContext *avctx)
{
    int ret;
    ret = ff_v4l2_m2m_codec_end(avctx->priv_data);
    if (ret) {
        av_log(avctx, AV_LOG_ERROR, "Encoder v4l2_m2m v4l2_encode_close ERROR "
            "ff_v4l2_m2m_codec_end failed ret=(%d) errno=(%d) error='%s'\n",
            ret, errno, strerror(errno));
        return ret;
    }
    return 0;
}

/*      
        NOTING: /usr/include/linux/v4l2_controls.h 
        ESPECIALLY  noting driver limits from: v4l2-ctl --list-ctrls-menu -d 11
             video_bitrate_mode 0x009909ce (menu)   : min=0 max=1 default=0 value=0 flags=update
				0: Variable Bitrate
				1: Constant Bitrate
                  video_bitrate 0x009909cf (int)    : min=25000 max=25000000 step=25000 default=10000000 value=10000000
           sequence_header_mode 0x009909d8 (menu)   : min=0 max=1 default=1 value=1
				0: Separate Buffer
				1: Joined With 1st Frame
         repeat_sequence_header 0x009909e2 (bool)   : default=0 value=0
                force_key_frame 0x009909e5 (button) : flags=write-only, execute-on-write
          h264_minimum_qp_value 0x00990a61 (int)    : min=0 max=51 step=1 default=20 value=20
          h264_maximum_qp_value 0x00990a62 (int)    : min=0 max=51 step=1 default=51 value=51
            h264_i_frame_period 0x00990a66 (int)    : min=0 max=2147483647 step=1 default=60 value=60
                     h264_level 0x00990a67 (menu)   : min=0 max=13 default=11 value=11
				0: 1
				1: 1b
				2: 1.1
				3: 1.2
				4: 1.3
				5: 2
				6: 2.1
				7: 2.2
				8: 3
				9: 3.1
				10: 3.2
				11: 4
				12: 4.1
				13: 4.2
                   h264_profile 0x00990a6b (menu)   : min=0 max=4 default=4 value=4
				0: Baseline
				1: Constrained Baseline
				2: Main
				4: High
*/

#define OFFSET(x) offsetof(V4L2m2mPriv, x)
#define FLAGS AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM

#define V4L_M2M_CAPTURE_OPTS \
    V4L_M2M_DEFAULT_OPTS,\
    { "num_capture_buffers", "Number of buffers in the capture context", \
        OFFSET(num_capture_buffers), AV_OPT_TYPE_INT, {.i64 = 4 }, 4, INT_MAX, FLAGS }

/**
   The following V4L_M2M_h264_options are parsed and stored in v4l2_m2m.h private typedef struct V4L2m2mPriv
   All of the code in this encoder DEPENDS on the Options below,
   "overriding" all "global" options having the same name.
   i.e. the defaults and allowable values and ranges HERE take precendence.
   Each codec has its own Options with the same names and different values.
 */
/**
   h264 - h264 part 10 AVC
 */
static const AVOption V4L_M2M_h264_options[] = {
    /**
       V4L_M2M_CAPTURE_OPTS contains num_output_buffers and num_capture_buffers
     */
    V4L_M2M_CAPTURE_OPTS,
    /**
       per https://github.com/raspberrypi/linux/issues/4917#issuecomment-1057977916
       Profile definitions from avcodec.h and v4l2-controls.h and videodev2.h
     */
    { "profile",              "Profile restrictions, eg -profile high",   
        OFFSET(h264_profile), AV_OPT_TYPE_INT, {.i64=V4L2_MPEG_VIDEO_H264_PROFILE_HIGH},
        V4L2_MPEG_VIDEO_H264_PROFILE_BASELINE, 
        V4L2_MPEG_VIDEO_H264_PROFILE_CONSTRAINED_HIGH, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "profile" },
    { "baseline",             "baseline",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_PROFILE_BASELINE},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "profile" },
    { "c_baseline",           "constrained_baseline",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_PROFILE_CONSTRAINED_BASELINE},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "profile" },
    { "main",                 "main",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_PROFILE_MAIN},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "profile" },
    { "high",                 "high",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_PROFILE_HIGH},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "profile" },
    { "high10",               "high 10",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_PROFILE_HIGH_10},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "profile" },
    { "high422",              "high 422",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_PROFILE_HIGH_422},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "profile" },
    { "high444",              "high 444 Predictive",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_PROFILE_HIGH_444_PREDICTIVE},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "profile" },
    { "high10_intra",         "high 10 Intra",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_PROFILE_HIGH_10_INTRA},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "profile" },
    { "high422_intra",        "high 422 Intra",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_PROFILE_HIGH_422_INTRA},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "profile" },
    { "high444_intra",        "high 444 Predictive Intra",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_PROFILE_HIGH_444_INTRA},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "profile" },
    { "calv444_intra",        "calvc 444 Intra",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_PROFILE_CAVLC_444_INTRA},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "profile" },
    { "scalable_baseline",    "scalable baseline",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_PROFILE_SCALABLE_BASELINE},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "profile" },
    { "scalable_high",        "scalable high",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_PROFILE_SCALABLE_HIGH},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "profile" },
    { "scalable_high_intra",  "scalable high intra",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_PROFILE_SCALABLE_HIGH_INTRA},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "profile" },
    { "stereo_high",          "stereo high",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_PROFILE_STEREO_HIGH},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "profile" },
    { "multiview_high",       "multiview high",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_PROFILE_MULTIVIEW_HIGH},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "profile" },
    { "constrained_high",       "constrained high",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_PROFILE_CONSTRAINED_HIGH},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "profile" },
    /**
       Profile Level definitions from avcodec.h and v4l2-controls.h and videodev2.h
     */
    { "level",                "Profile Level restrictions, eg 4.2",
        OFFSET(h264_level), AV_OPT_TYPE_INT, {.i64=V4L2_MPEG_VIDEO_H264_LEVEL_4_2},
        V4L2_MPEG_VIDEO_H264_LEVEL_1_0,
        V4L2_MPEG_VIDEO_H264_LEVEL_6_2, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "level" },
    { "1",                    "level 1",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_LEVEL_1_0},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "level" },
    { "1B",                   "level 1B",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_LEVEL_1B},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "level" },
    { "1.1",                  "level 1.1",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_LEVEL_1_1},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "level" },
    { "1.2",                  "level 1.2",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_LEVEL_1_2},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "level" },
    { "1.3",                  "level 1.3",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_LEVEL_1_3},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "level" },
    { "2",                    "level 2",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_LEVEL_2_0},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "level" },
    { "2.1",                  "level 2.1",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_LEVEL_2_1},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "level" },
    { "2.2",                  "level 2.1",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_LEVEL_2_2},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "level" },
    { "3",                    "level 3",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_LEVEL_3_0},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "level" },
    { "3.1",                  "level 3.1",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_LEVEL_3_1},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "level" },
    { "3.2",                  "level 3.2",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_LEVEL_3_2},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "level" },
    { "4",                    "level 4",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_LEVEL_4_0},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "level" },
    { "4.1",                  "level 4.1",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_LEVEL_4_1},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "level" },
    { "4.2",                  "level 4.2",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_LEVEL_4_2},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "level" },
    { "5",                    "level 5",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_LEVEL_5_0},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "level" },
    { "5.1",                  "level 5.1",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_LEVEL_5_1},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "level" },
    { "5.2",                  "level 5.2",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_LEVEL_5_2},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "level" },
    { "6",                    "level 6",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_LEVEL_6_0},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "level" },
    { "6.1",                  "level 6.1",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_LEVEL_6_1},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "level" },
    { "6.2",                  "level 6.2",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_H264_LEVEL_6_2},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "level" },
    /**
       video_bitrate_mode is either CBR or VBR or CQ ... here called eg -rc CBR or -rc VBR 
        ... default to VBR, since CBR crashes with:
            ERROR VIDIOC_STREAMON failed on output context ret=(-3) errno=(3 'No such process')
     */
    { "rc",                   "Bitrate mode VBR or CBR or CQ",
        OFFSET(h264_video_bit_rate_mode), AV_OPT_TYPE_INT, {.i64=V4L2_MPEG_VIDEO_BITRATE_MODE_VBR},
        V4L2_MPEG_VIDEO_BITRATE_MODE_VBR,
        V4L2_MPEG_VIDEO_BITRATE_MODE_CQ, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "rc" },
    { "VBR",                  "for variable bitrate mode",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_BITRATE_MODE_VBR},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "rc" },
    /**
       CBR: 1. CBR is not supported in high profile on the Raspberry Pi SoC. 
             2. CBR causes ffmpeg encoder to hang on the Raspberry Pi.
     */
    { "CBR",                  "for constant bitrate mode",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_BITRATE_MODE_CBR},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "rc" },
    /**
       CQ: https://lkml.org/lkml/2020/5/22/1219
               When V4L2_CID_MPEG_VIDEO_BITRATE_MODE value is V4L2_MPEG_VIDEO_BITRATE_MODE_CQ,
               encoder will produce constant quality output indicated by the 
               V4L2_CID_MPEG_VIDEO_CONSTANT_QUALITY control value. Encoder will choose
               appropriate quantization parameter and bitrate to produce requested frame quality level.
               Valid range is 1 to 100 where 1 = lowest quality, 100 = highest quality.
           ** V4L2_CID_MPEG_VIDEO_CONSTANT_QUALITY not dealt with here ... since
              mode V4L2_MPEG_VIDEO_BITRATE_MODE_CQ is not allowed on a Raspberry Pi 4.
       sequence_header_mode is peculiar ... here called -shm separate_buffer or -shm joined_1st_frame    
     */
    { "CQ",                  "for constant quality mode",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_BITRATE_MODE_CQ},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "rc" },
    { "shm",                  "Sequence_header_mode",
        OFFSET(h264_sequence_header_mode), AV_OPT_TYPE_INT, {.i64=V4L2_MPEG_VIDEO_HEADER_MODE_JOINED_WITH_1ST_FRAME},
        V4L2_MPEG_VIDEO_HEADER_MODE_SEPARATE,
        V4L2_MPEG_VIDEO_HEADER_MODE_JOINED_WITH_1ST_FRAME, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "shm" },
    { "separate_buffer",      "separate_buffer",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_HEADER_MODE_SEPARATE},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "shm" },
    { "joined_1st_frame",     "joined_1st_frame",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_HEADER_MODE_JOINED_WITH_1ST_FRAME},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "shm" },
    /**
       Repeat Sequence Headers (Raspberry Pi respositories compile with this on) 
       ... here called -rsh 0 or -rsh 0
     */
    { "rsh",                  "repeat sequence header 0(false) 1(true)",
        OFFSET(h264_repeat_seq_header), AV_OPT_TYPE_BOOL, {.i64=1},
        0, 1, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM },
    /**
       Frame Skip Mode here called -fsm. V4L2_CID_MPEG_VIDEO_FRAME_SKIP_MODE 
       Indicates in what conditions the encoder should skip frames. 
       If encoding a frame would cause the encoded stream to be larger than
       a chosen data limit then the frame will be skipped.
     */
    { "fsme",                 "Frame Skip Mode for encoder",
        OFFSET(h264_frame_skip_mode_encoder), AV_OPT_TYPE_INT, {.i64=V4L2_MPEG_VIDEO_FRAME_SKIP_MODE_DISABLED},
        V4L2_MPEG_VIDEO_FRAME_SKIP_MODE_DISABLED,
        V4L2_MPEG_VIDEO_FRAME_SKIP_MODE_BUF_LIMIT, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "fsme" },
    { "disabled",             "fsme disabled",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_FRAME_SKIP_MODE_DISABLED},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "fsme" },
    { "level_limit",          "fsme enabled and buffer limit is set by the chosen level",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_FRAME_SKIP_MODE_LEVEL_LIMIT},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "fsme" },
    { "buffer_limit",         "fsme enabled and buffer limit is set by CPB (H264) buffer size control",
        0, AV_OPT_TYPE_CONST, {.i64=V4L2_MPEG_VIDEO_FRAME_SKIP_MODE_BUF_LIMIT},
        0, 0, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM, "fsme" },
    /**
       Video_bitrate -b:v for both CBR and VBR
     */
    { "b",                    "-b:v video_bitrate bits per second",
        OFFSET(h264_video_bit_rate), AV_OPT_TYPE_INT64, {.i64=10000000},
            25000, 25000000, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM },
    { "qmin",                 "Minimum quantization parameter for h264",
        OFFSET(h264_qmin), AV_OPT_TYPE_INT, {.i64=1},
        1, 51, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM },
    { "qmax",                 "Maximum quantization parameter for h264",
        OFFSET(h264_qmax), AV_OPT_TYPE_INT, {.i64=51},
        1, 51, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM },
    /**
       Since GOP setting is not currently used by the driver,
       Accept it privately and if specified then allow it to over-ride iframe_period
     */
    { "g",                    "gop size, overrides iframe_period used by the driver",
        OFFSET(h264_gop_size), AV_OPT_TYPE_INT, {.i64=-1},
        -1, INT_MAX, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM },
    /**
       Allow iframe_period to be used directly (over-ridden by a GOP setting):
           "For H264 there is V4L2_CID_MPEG_VIDEO_H264_I_PERIOD, which is what is implemented in the encoder" 
           per https://github.com/raspberrypi/linux/issues/4917#issuecomment-1057977916
     */
    { "iframe_period",        "iframe_period used by the driver; overridden by -g",
        OFFSET(h264_iframe_period), AV_OPT_TYPE_INT, {.i64=25},
        0, INT_MAX, AV_OPT_FLAG_VIDEO_PARAM | AV_OPT_FLAG_ENCODING_PARAM },
    { NULL },
};

/**
   mpeg4 options
 */
static const AVOption V4L_M2M_mpeg4_options[] = {
    V4L_M2M_CAPTURE_OPTS,
    FF_MPEG4_PROFILE_OPTS
    { NULL },
};

/**
   Something for num_output_buffers and num_capture_buffers
 */
static const AVOption V4L_M2M_options[] = {
    /// V4L_M2M_CAPTURE_OPTS contains num_output_buffers and num_capture_buffers
    V4L_M2M_CAPTURE_OPTS,
    { NULL },
};

/**
   info at https://stackoverflow.com/questions/12648988/converting-a-defined-constant-number-to-a-string
 */
#define STRINGIZE_(x) #x
#define STRINGIZE(x) STRINGIZE_(x)
static const FFCodecDefault v4l2_m2m_defaults[] = {
    { NULL },
};

#define M2MENC_CLASS(NAME, OPTIONS_NAME) \
    static const AVClass v4l2_m2m_ ## NAME ## _enc_class = { \
        .class_name = #NAME "_v4l2m2m_encoder", \
        .item_name  = av_default_item_name, \
        .option     = OPTIONS_NAME, \
        .version    = LIBAVUTIL_VERSION_INT, \
    };

#define M2MENC(NAME, LONGNAME, OPTIONS_NAME, CODEC) \
    M2MENC_CLASS(NAME, OPTIONS_NAME) \
    const FFCodec ff_ ## NAME ## _v4l2m2m_encoder = { \
        .p.name         = #NAME "_v4l2m2m" , \
        .p.long_name    = NULL_IF_CONFIG_SMALL("V4L2 mem2mem " LONGNAME " encoder wrapper"), \
        .p.type         = AVMEDIA_TYPE_VIDEO, \
        .p.id           = CODEC , \
        .priv_data_size = sizeof(V4L2m2mPriv), \
        .p.priv_class   = &v4l2_m2m_ ## NAME ##_enc_class, \
        .init           = v4l2_encode_init, \
        .receive_packet = v4l2_receive_packet, \
        .close          = v4l2_encode_close, \
        .defaults       = v4l2_m2m_defaults, \
        .p.capabilities = AV_CODEC_CAP_HARDWARE | AV_CODEC_CAP_DELAY, \
        .caps_internal  = FF_CODEC_CAP_INIT_CLEANUP, \
        .p.wrapper_name = "v4l2m2m", \
    }

/**
   also see v4l2_m2m.h typedef struct V4L2m2mPriv
 */
M2MENC(h264,  "H.264", V4L_M2M_h264_options,  AV_CODEC_ID_H264);    
M2MENC(mpeg4, "MPEG4", V4L_M2M_mpeg4_options, AV_CODEC_ID_MPEG4);
M2MENC(hevc,  "HEVC",  V4L_M2M_options,       AV_CODEC_ID_HEVC);
M2MENC(vp8,   "VP8",   V4L_M2M_options,       AV_CODEC_ID_VP8);
M2MENC(vp9,   "VP9",   V4L_M2M_options,       AV_CODEC_ID_VP9);
M2MENC(h263,  "H.263", V4L_M2M_options,       AV_CODEC_ID_H263);
