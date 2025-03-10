/*
 *  Copyright 2023 The LibYuv Project Authors. All rights reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

/*
 * Copyright (c) 2023 SiFive, Inc. All rights reserved.
 *
 * Contributed by Darren Hsieh <darren.hsieh@sifive.com>
 * Contributed by Bruce Lai <bruce.lai@sifive.com>
 */

#include "libyuv/row.h"

#if !defined(LIBYUV_DISABLE_RVV) && defined(__riscv_vector)
#include <assert.h>
#include <riscv_vector.h>

#ifdef __cplusplus
namespace libyuv {
extern "C" {
#endif

// Fill YUV -> RGB conversion constants into vectors
// NOTE: To match behavior on other platforms, vxrm (fixed-point rounding mode
// register) is set to round-to-nearest-up mode(0).
#define YUVTORGB_SETUP(yuvconst, vl, v_ub, v_vr, v_ug, v_vg, v_yg, v_bb, v_bg, \
                       v_br)                                                   \
  {                                                                            \
    asm volatile("csrwi vxrm, 0");                                             \
    vl = __riscv_vsetvl_e8m1(w);                                               \
    v_ub = __riscv_vmv_v_x_u8m1(yuvconst->kUVCoeff[0], vl);                    \
    v_vr = __riscv_vmv_v_x_u8m1(yuvconst->kUVCoeff[1], vl);                    \
    v_ug = __riscv_vmv_v_x_u8m1(yuvconst->kUVCoeff[2], vl);                    \
    v_vg = __riscv_vmv_v_x_u8m1(yuvconst->kUVCoeff[3], vl);                    \
    v_yg = __riscv_vmv_v_x_u16m2(yuvconst->kRGBCoeffBias[0], vl);              \
    v_bb = __riscv_vmv_v_x_u16m2(yuvconst->kRGBCoeffBias[1] + 32, vl);         \
    v_bg = __riscv_vmv_v_x_u16m2(yuvconst->kRGBCoeffBias[2] - 32, vl);         \
    v_br = __riscv_vmv_v_x_u16m2(yuvconst->kRGBCoeffBias[3] + 32, vl);         \
  }

// Read [VLEN/8] Y, [VLEN/(8 * 2)] U and [VLEN/(8 * 2)] V from 422
#define READYUV422(vl, v_u, v_v, v_y_16)                \
  {                                                     \
    vuint8mf2_t v_tmp0, v_tmp1;                         \
    vuint8m1_t v_y;                                     \
    vuint16m1_t v_u_16, v_v_16;                         \
    vl = __riscv_vsetvl_e8mf2((w + 1) / 2);             \
    v_tmp0 = __riscv_vle8_v_u8mf2(src_u, vl);           \
    v_u_16 = __riscv_vwaddu_vx_u16m1(v_tmp0, 0, vl);    \
    v_tmp1 = __riscv_vle8_v_u8mf2(src_v, vl);           \
    v_v_16 = __riscv_vwaddu_vx_u16m1(v_tmp1, 0, vl);    \
    v_v_16 = __riscv_vmul_vx_u16m1(v_v_16, 0x0101, vl); \
    v_u_16 = __riscv_vmul_vx_u16m1(v_u_16, 0x0101, vl); \
    v_v = __riscv_vreinterpret_v_u16m1_u8m1(v_v_16);    \
    v_u = __riscv_vreinterpret_v_u16m1_u8m1(v_u_16);    \
    vl = __riscv_vsetvl_e8m1(w);                        \
    v_y = __riscv_vle8_v_u8m1(src_y, vl);               \
    v_y_16 = __riscv_vwaddu_vx_u16m2(v_y, 0, vl);       \
  }

// Read [VLEN/8] Y, [VLEN/8] U, and [VLEN/8] V from 444
#define READYUV444(vl, v_u, v_v, v_y_16)          \
  {                                               \
    vuint8m1_t v_y;                               \
    vl = __riscv_vsetvl_e8m1(w);                  \
    v_y = __riscv_vle8_v_u8m1(src_y, vl);         \
    v_u = __riscv_vle8_v_u8m1(src_u, vl);         \
    v_v = __riscv_vle8_v_u8m1(src_v, vl);         \
    v_y_16 = __riscv_vwaddu_vx_u16m2(v_y, 0, vl); \
  }

// Convert from YUV to fixed point RGB
#define YUVTORGB(vl, v_u, v_v, v_ub, v_vr, v_ug, v_vg, v_yg, v_bb, v_bg, v_br, \
                 v_y_16, v_g_16, v_b_16, v_r_16)                               \
  {                                                                            \
    vuint16m2_t v_tmp0, v_tmp1, v_tmp2, v_tmp3, v_tmp4;                        \
    vuint32m4_t v_tmp5;                                                        \
    v_tmp0 = __riscv_vwmulu_vv_u16m2(v_u, v_ug, vl);                           \
    v_y_16 = __riscv_vmul_vx_u16m2(v_y_16, 0x0101, vl);                        \
    v_tmp0 = __riscv_vwmaccu_vv_u16m2(v_tmp0, v_vg, v_v, vl);                  \
    v_tmp1 = __riscv_vwmulu_vv_u16m2(v_u, v_ub, vl);                           \
    v_tmp5 = __riscv_vwmulu_vv_u32m4(v_y_16, v_yg, vl);                        \
    v_tmp2 = __riscv_vnsrl_wx_u16m2(v_tmp5, 16, vl);                           \
    v_tmp3 = __riscv_vadd_vv_u16m2(v_tmp2, v_bg, vl);                          \
    v_tmp4 = __riscv_vadd_vv_u16m2(v_tmp2, v_tmp1, vl);                        \
    v_tmp2 = __riscv_vwmaccu_vv_u16m2(v_tmp2, v_vr, v_v, vl);                  \
    v_g_16 = __riscv_vssubu_vv_u16m2(v_tmp3, v_tmp0, vl);                      \
    v_b_16 = __riscv_vssubu_vv_u16m2(v_tmp4, v_bb, vl);                        \
    v_r_16 = __riscv_vssubu_vv_u16m2(v_tmp2, v_br, vl);                        \
  }

// Convert from fixed point RGB To 8 bit RGB
#define RGBTORGB8(vl, v_g_16, v_b_16, v_r_16, v_g, v_b, v_r) \
  {                                                          \
    v_g = __riscv_vnclipu_wx_u8m1(v_g_16, 6, vl);            \
    v_b = __riscv_vnclipu_wx_u8m1(v_b_16, 6, vl);            \
    v_r = __riscv_vnclipu_wx_u8m1(v_r_16, 6, vl);            \
  }

void ARGBToAR64Row_RVV(const uint8_t* src_argb, uint16_t* dst_ar64, int width) {
  size_t avl = (size_t)4 * width;
  do {
    vuint16m8_t v_ar64;
    vuint8m4_t v_argb;
    size_t vl = __riscv_vsetvl_e8m4(avl);
    v_argb = __riscv_vle8_v_u8m4(src_argb, vl);
    v_ar64 = __riscv_vwaddu_vx_u16m8(v_argb, 0, vl);
    v_ar64 = __riscv_vmul_vx_u16m8(v_ar64, 0x0101, vl);
    __riscv_vse16_v_u16m8(dst_ar64, v_ar64, vl);
    avl -= vl;
    src_argb += vl;
    dst_ar64 += vl;
  } while (avl > 0);
}

void ARGBToAB64Row_RVV(const uint8_t* src_argb, uint16_t* dst_ab64, int width) {
  size_t avl = (size_t)width;
  do {
    vuint16m2_t v_b_16, v_g_16, v_r_16, v_a_16;
    vuint8m1_t v_b, v_g, v_r, v_a;
    size_t vl = __riscv_vsetvl_e8m1(avl);
    __riscv_vlseg4e8_v_u8m1(&v_b, &v_g, &v_r, &v_a, src_argb, vl);
    v_b_16 = __riscv_vwaddu_vx_u16m2(v_b, 0, vl);
    v_g_16 = __riscv_vwaddu_vx_u16m2(v_g, 0, vl);
    v_r_16 = __riscv_vwaddu_vx_u16m2(v_r, 0, vl);
    v_a_16 = __riscv_vwaddu_vx_u16m2(v_a, 0, vl);
    v_b_16 = __riscv_vmul_vx_u16m2(v_b_16, 0x0101, vl);
    v_g_16 = __riscv_vmul_vx_u16m2(v_g_16, 0x0101, vl);
    v_r_16 = __riscv_vmul_vx_u16m2(v_r_16, 0x0101, vl);
    v_a_16 = __riscv_vmul_vx_u16m2(v_a_16, 0x0101, vl);
    __riscv_vsseg4e16_v_u16m2(dst_ab64, v_r_16, v_g_16, v_b_16, v_a_16, vl);
    avl -= vl;
    src_argb += 4 * vl;
    dst_ab64 += 4 * vl;
  } while (avl > 0);
}

void AR64ToARGBRow_RVV(const uint16_t* src_ar64, uint8_t* dst_argb, int width) {
  size_t avl = (size_t)4 * width;
  do {
    vuint16m8_t v_ar64;
    vuint8m4_t v_argb;
    size_t vl = __riscv_vsetvl_e16m8(avl);
    v_ar64 = __riscv_vle16_v_u16m8(src_ar64, vl);
    v_argb = __riscv_vnsrl_wx_u8m4(v_ar64, 8, vl);
    __riscv_vse8_v_u8m4(dst_argb, v_argb, vl);
    avl -= vl;
    src_ar64 += vl;
    dst_argb += vl;
  } while (avl > 0);
}

void AB64ToARGBRow_RVV(const uint16_t* src_ab64, uint8_t* dst_argb, int width) {
  size_t avl = (size_t)width;
  do {
    vuint16m2_t v_b_16, v_g_16, v_r_16, v_a_16;
    vuint8m1_t v_b, v_g, v_r, v_a;
    size_t vl = __riscv_vsetvl_e16m2(avl);
    __riscv_vlseg4e16_v_u16m2(&v_r_16, &v_g_16, &v_b_16, &v_a_16, src_ab64, vl);
    v_b = __riscv_vnsrl_wx_u8m1(v_b_16, 8, vl);
    v_g = __riscv_vnsrl_wx_u8m1(v_g_16, 8, vl);
    v_r = __riscv_vnsrl_wx_u8m1(v_r_16, 8, vl);
    v_a = __riscv_vnsrl_wx_u8m1(v_a_16, 8, vl);
    __riscv_vsseg4e8_v_u8m1(dst_argb, v_b, v_g, v_r, v_a, vl);
    avl -= vl;
    src_ab64 += 4 * vl;
    dst_argb += 4 * vl;
  } while (avl > 0);
}

void RAWToARGBRow_RVV(const uint8_t* src_raw, uint8_t* dst_argb, int width) {
  size_t w = (size_t)width;
  size_t vl = __riscv_vsetvl_e8m2(w);
  vuint8m2_t v_a = __riscv_vmv_v_x_u8m2(255u, vl);
  do {
    vuint8m2_t v_b, v_g, v_r;
    __riscv_vlseg3e8_v_u8m2(&v_r, &v_g, &v_b, src_raw, vl);
    __riscv_vsseg4e8_v_u8m2(dst_argb, v_b, v_g, v_r, v_a, vl);
    w -= vl;
    src_raw += vl * 3;
    dst_argb += vl * 4;
    vl = __riscv_vsetvl_e8m2(w);
  } while (w > 0);
}

void RAWToRGBARow_RVV(const uint8_t* src_raw, uint8_t* dst_rgba, int width) {
  size_t w = (size_t)width;
  size_t vl = __riscv_vsetvl_e8m2(w);
  vuint8m2_t v_a = __riscv_vmv_v_x_u8m2(255u, vl);
  do {
    vuint8m2_t v_b, v_g, v_r;
    __riscv_vlseg3e8_v_u8m2(&v_r, &v_g, &v_b, src_raw, vl);
    __riscv_vsseg4e8_v_u8m2(dst_rgba, v_a, v_b, v_g, v_r, vl);
    w -= vl;
    src_raw += vl * 3;
    dst_rgba += vl * 4;
    vl = __riscv_vsetvl_e8m2(w);
  } while (w > 0);
}

void RAWToRGB24Row_RVV(const uint8_t* src_raw, uint8_t* dst_rgb24, int width) {
  size_t w = (size_t)width;
  do {
    vuint8m2_t v_b, v_g, v_r;
    size_t vl = __riscv_vsetvl_e8m2(w);
    __riscv_vlseg3e8_v_u8m2(&v_b, &v_g, &v_r, src_raw, vl);
    __riscv_vsseg3e8_v_u8m2(dst_rgb24, v_r, v_g, v_b, vl);
    w -= vl;
    src_raw += vl * 3;
    dst_rgb24 += vl * 3;
  } while (w > 0);
}

void ARGBToRAWRow_RVV(const uint8_t* src_argb, uint8_t* dst_raw, int width) {
  size_t w = (size_t)width;
  do {
    vuint8m2_t v_b, v_g, v_r, v_a;
    size_t vl = __riscv_vsetvl_e8m2(w);
    __riscv_vlseg4e8_v_u8m2(&v_b, &v_g, &v_r, &v_a, src_argb, vl);
    __riscv_vsseg3e8_v_u8m2(dst_raw, v_r, v_g, v_b, vl);
    w -= vl;
    src_argb += vl * 4;
    dst_raw += vl * 3;
  } while (w > 0);
}

void ARGBToRGB24Row_RVV(const uint8_t* src_argb,
                        uint8_t* dst_rgb24,
                        int width) {
  size_t w = (size_t)width;
  do {
    vuint8m2_t v_b, v_g, v_r, v_a;
    size_t vl = __riscv_vsetvl_e8m2(w);
    __riscv_vlseg4e8_v_u8m2(&v_b, &v_g, &v_r, &v_a, src_argb, vl);
    __riscv_vsseg3e8_v_u8m2(dst_rgb24, v_b, v_g, v_r, vl);
    w -= vl;
    src_argb += vl * 4;
    dst_rgb24 += vl * 3;
  } while (w > 0);
}

void RGB24ToARGBRow_RVV(const uint8_t* src_rgb24,
                        uint8_t* dst_argb,
                        int width) {
  size_t w = (size_t)width;
  size_t vl = __riscv_vsetvl_e8m2(w);
  vuint8m2_t v_a = __riscv_vmv_v_x_u8m2(255u, vl);
  do {
    vuint8m2_t v_b, v_g, v_r;
    __riscv_vlseg3e8_v_u8m2(&v_b, &v_g, &v_r, src_rgb24, vl);
    __riscv_vsseg4e8_v_u8m2(dst_argb, v_b, v_g, v_r, v_a, vl);
    w -= vl;
    src_rgb24 += vl * 3;
    dst_argb += vl * 4;
    vl = __riscv_vsetvl_e8m2(w);
  } while (w > 0);
}

void I444ToARGBRow_RVV(const uint8_t* src_y,
                       const uint8_t* src_u,
                       const uint8_t* src_v,
                       uint8_t* dst_argb,
                       const struct YuvConstants* yuvconstants,
                       int width) {
  size_t vl;
  size_t w = (size_t)width;
  vuint8m1_t v_u, v_v;
  vuint8m1_t v_ub, v_vr, v_ug, v_vg;
  vuint8m1_t v_b, v_g, v_r, v_a;
  vuint16m2_t v_yg, v_bb, v_bg, v_br;
  vuint16m2_t v_y_16, v_g_16, v_b_16, v_r_16;
  YUVTORGB_SETUP(yuvconstants, vl, v_ub, v_vr, v_ug, v_vg, v_yg, v_bb, v_bg,
                 v_br);
  v_a = __riscv_vmv_v_x_u8m1(255u, vl);
  do {
    READYUV444(vl, v_u, v_v, v_y_16);
    YUVTORGB(vl, v_u, v_v, v_ub, v_vr, v_ug, v_vg, v_yg, v_bb, v_bg, v_br,
             v_y_16, v_g_16, v_b_16, v_r_16);
    RGBTORGB8(vl, v_g_16, v_b_16, v_r_16, v_g, v_b, v_r);
    __riscv_vsseg4e8_v_u8m1(dst_argb, v_b, v_g, v_r, v_a, vl);
    w -= vl;
    src_y += vl;
    src_u += vl;
    src_v += vl;
    dst_argb += vl * 4;
  } while (w > 0);
}

void I444AlphaToARGBRow_RVV(const uint8_t* src_y,
                            const uint8_t* src_u,
                            const uint8_t* src_v,
                            const uint8_t* src_a,
                            uint8_t* dst_argb,
                            const struct YuvConstants* yuvconstants,
                            int width) {
  size_t vl;
  size_t w = (size_t)width;
  vuint8m1_t v_u, v_v;
  vuint8m1_t v_ub, v_vr, v_ug, v_vg;
  vuint8m1_t v_b, v_g, v_r, v_a;
  vuint16m2_t v_yg, v_bb, v_bg, v_br;
  vuint16m2_t v_y_16, v_g_16, v_b_16, v_r_16;
  YUVTORGB_SETUP(yuvconstants, vl, v_ub, v_vr, v_ug, v_vg, v_yg, v_bb, v_bg,
                 v_br);
  do {
    READYUV444(vl, v_u, v_v, v_y_16);
    v_a = __riscv_vle8_v_u8m1(src_a, vl);
    YUVTORGB(vl, v_u, v_v, v_ub, v_vr, v_ug, v_vg, v_yg, v_bb, v_bg, v_br,
             v_y_16, v_g_16, v_b_16, v_r_16);
    RGBTORGB8(vl, v_g_16, v_b_16, v_r_16, v_g, v_b, v_r);
    __riscv_vsseg4e8_v_u8m1(dst_argb, v_b, v_g, v_r, v_a, vl);
    w -= vl;
    src_y += vl;
    src_a += vl;
    src_u += vl;
    src_v += vl;
    dst_argb += vl * 4;
  } while (w > 0);
}

void I444ToRGB24Row_RVV(const uint8_t* src_y,
                        const uint8_t* src_u,
                        const uint8_t* src_v,
                        uint8_t* dst_rgb24,
                        const struct YuvConstants* yuvconstants,
                        int width) {
  size_t vl;
  size_t w = (size_t)width;
  vuint8m1_t v_u, v_v;
  vuint8m1_t v_ub, v_vr, v_ug, v_vg;
  vuint8m1_t v_b, v_g, v_r;
  vuint16m2_t v_yg, v_bb, v_bg, v_br;
  vuint16m2_t v_y_16, v_g_16, v_b_16, v_r_16;
  YUVTORGB_SETUP(yuvconstants, vl, v_ub, v_vr, v_ug, v_vg, v_yg, v_bb, v_bg,
                 v_br);
  do {
    READYUV444(vl, v_u, v_v, v_y_16);
    YUVTORGB(vl, v_u, v_v, v_ub, v_vr, v_ug, v_vg, v_yg, v_bb, v_bg, v_br,
             v_y_16, v_g_16, v_b_16, v_r_16);
    RGBTORGB8(vl, v_g_16, v_b_16, v_r_16, v_g, v_b, v_r);
    __riscv_vsseg3e8_v_u8m1(dst_rgb24, v_b, v_g, v_r, vl);
    w -= vl;
    src_y += vl;
    src_u += vl;
    src_v += vl;
    dst_rgb24 += vl * 3;
  } while (w > 0);
}

void I422ToARGBRow_RVV(const uint8_t* src_y,
                       const uint8_t* src_u,
                       const uint8_t* src_v,
                       uint8_t* dst_argb,
                       const struct YuvConstants* yuvconstants,
                       int width) {
  size_t vl;
  size_t w = (size_t)width;
  vuint8m1_t v_u, v_v;
  vuint8m1_t v_ub, v_vr, v_ug, v_vg;
  vuint8m1_t v_b, v_g, v_r, v_a;
  vuint16m2_t v_yg, v_bb, v_bg, v_br;
  vuint16m2_t v_y_16, v_g_16, v_b_16, v_r_16;
  YUVTORGB_SETUP(yuvconstants, vl, v_ub, v_vr, v_ug, v_vg, v_yg, v_bb, v_bg,
                 v_br);
  v_a = __riscv_vmv_v_x_u8m1(255u, vl);
  do {
    READYUV422(vl, v_u, v_v, v_y_16);
    YUVTORGB(vl, v_u, v_v, v_ub, v_vr, v_ug, v_vg, v_yg, v_bb, v_bg, v_br,
             v_y_16, v_g_16, v_b_16, v_r_16);
    RGBTORGB8(vl, v_g_16, v_b_16, v_r_16, v_g, v_b, v_r);
    __riscv_vsseg4e8_v_u8m1(dst_argb, v_b, v_g, v_r, v_a, vl);
    w -= vl;
    src_y += vl;
    src_u += vl / 2;
    src_v += vl / 2;
    dst_argb += vl * 4;
  } while (w > 0);
}

void I422AlphaToARGBRow_RVV(const uint8_t* src_y,
                            const uint8_t* src_u,
                            const uint8_t* src_v,
                            const uint8_t* src_a,
                            uint8_t* dst_argb,
                            const struct YuvConstants* yuvconstants,
                            int width) {
  size_t vl;
  size_t w = (size_t)width;
  vuint8m1_t v_u, v_v;
  vuint8m1_t v_ub, v_vr, v_ug, v_vg;
  vuint8m1_t v_b, v_g, v_r, v_a;
  vuint16m2_t v_yg, v_bb, v_bg, v_br;
  vuint16m2_t v_y_16, v_g_16, v_b_16, v_r_16;
  YUVTORGB_SETUP(yuvconstants, vl, v_ub, v_vr, v_ug, v_vg, v_yg, v_bb, v_bg,
                 v_br);
  do {
    READYUV422(vl, v_u, v_v, v_y_16);
    v_a = __riscv_vle8_v_u8m1(src_a, vl);
    YUVTORGB(vl, v_u, v_v, v_ub, v_vr, v_ug, v_vg, v_yg, v_bb, v_bg, v_br,
             v_y_16, v_g_16, v_b_16, v_r_16);
    RGBTORGB8(vl, v_g_16, v_b_16, v_r_16, v_g, v_b, v_r);
    __riscv_vsseg4e8_v_u8m1(dst_argb, v_b, v_g, v_r, v_a, vl);
    w -= vl;
    src_y += vl;
    src_a += vl;
    src_u += vl / 2;
    src_v += vl / 2;
    dst_argb += vl * 4;
  } while (w > 0);
}

void I422ToRGBARow_RVV(const uint8_t* src_y,
                       const uint8_t* src_u,
                       const uint8_t* src_v,
                       uint8_t* dst_rgba,
                       const struct YuvConstants* yuvconstants,
                       int width) {
  size_t vl;
  size_t w = (size_t)width;
  vuint8m1_t v_u, v_v;
  vuint8m1_t v_ub, v_vr, v_ug, v_vg;
  vuint8m1_t v_b, v_g, v_r, v_a;
  vuint16m2_t v_yg, v_bb, v_bg, v_br;
  vuint16m2_t v_y_16, v_g_16, v_b_16, v_r_16;
  YUVTORGB_SETUP(yuvconstants, vl, v_ub, v_vr, v_ug, v_vg, v_yg, v_bb, v_bg,
                 v_br);
  v_a = __riscv_vmv_v_x_u8m1(255u, vl);
  do {
    READYUV422(vl, v_u, v_v, v_y_16);
    YUVTORGB(vl, v_u, v_v, v_ub, v_vr, v_ug, v_vg, v_yg, v_bb, v_bg, v_br,
             v_y_16, v_g_16, v_b_16, v_r_16);
    RGBTORGB8(vl, v_g_16, v_b_16, v_r_16, v_g, v_b, v_r);
    __riscv_vsseg4e8_v_u8m1(dst_rgba, v_a, v_b, v_g, v_r, vl);
    w -= vl;
    src_y += vl;
    src_u += vl / 2;
    src_v += vl / 2;
    dst_rgba += vl * 4;
  } while (w > 0);
}

void I422ToRGB24Row_RVV(const uint8_t* src_y,
                        const uint8_t* src_u,
                        const uint8_t* src_v,
                        uint8_t* dst_rgb24,
                        const struct YuvConstants* yuvconstants,
                        int width) {
  size_t vl;
  size_t w = (size_t)width;
  vuint8m1_t v_u, v_v;
  vuint8m1_t v_ub, v_vr, v_ug, v_vg;
  vuint8m1_t v_b, v_g, v_r;
  vuint16m2_t v_yg, v_bb, v_bg, v_br;
  vuint16m2_t v_y_16, v_g_16, v_b_16, v_r_16;
  YUVTORGB_SETUP(yuvconstants, vl, v_ub, v_vr, v_ug, v_vg, v_yg, v_bb, v_bg,
                 v_br);
  do {
    READYUV422(vl, v_u, v_v, v_y_16);
    YUVTORGB(vl, v_u, v_v, v_ub, v_vr, v_ug, v_vg, v_yg, v_bb, v_bg, v_br,
             v_y_16, v_g_16, v_b_16, v_r_16);
    RGBTORGB8(vl, v_g_16, v_b_16, v_r_16, v_g, v_b, v_r);
    __riscv_vsseg3e8_v_u8m1(dst_rgb24, v_b, v_g, v_r, vl);
    w -= vl;
    src_y += vl;
    src_u += vl / 2;
    src_v += vl / 2;
    dst_rgb24 += vl * 3;
  } while (w > 0);
}

void I400ToARGBRow_RVV(const uint8_t* src_y,
                       uint8_t* dst_argb,
                       const struct YuvConstants* yuvconstants,
                       int width) {
  size_t w = (size_t)width;
  size_t vl = __riscv_vsetvl_e8m2(w);
  const bool is_yb_positive = (yuvconstants->kRGBCoeffBias[4] >= 0);
  vuint8m2_t v_a = __riscv_vmv_v_x_u8m2(255u, vl);
  vuint16m4_t v_yb;
  vuint16m4_t v_yg = __riscv_vmv_v_x_u16m4(yuvconstants->kRGBCoeffBias[0], vl);
  // To match behavior on other platforms, vxrm (fixed-point rounding mode
  // register) sets to round-to-nearest-up mode(0).
  asm volatile("csrwi vxrm, 0");
  if (is_yb_positive) {
    v_yb = __riscv_vmv_v_x_u16m4(yuvconstants->kRGBCoeffBias[4] - 32, vl);
  } else {
    v_yb = __riscv_vmv_v_x_u16m4(-yuvconstants->kRGBCoeffBias[4] + 32, vl);
  }
  do {
    vuint8m2_t v_y, v_out;
    vuint16m4_t v_y_16, v_tmp0, v_tmp1, v_tmp2;
    vl = __riscv_vsetvl_e8m2(w);
    v_y = __riscv_vle8_v_u8m2(src_y, vl);
    v_y_16 = __riscv_vwaddu_vx_u16m4(v_y, 0, vl);
    v_tmp0 = __riscv_vmul_vx_u16m4(v_y_16, 0x0101, vl);  // 257 * v_y
    v_tmp1 = __riscv_vmulhu_vv_u16m4(v_tmp0, v_yg, vl);
    if (is_yb_positive) {
      v_tmp2 = __riscv_vsaddu_vv_u16m4(v_tmp1, v_yb, vl);
    } else {
      v_tmp2 = __riscv_vssubu_vv_u16m4(v_tmp1, v_yb, vl);
    }
    v_out = __riscv_vnclipu_wx_u8m2(v_tmp2, 6, vl);
    __riscv_vsseg4e8_v_u8m2(dst_argb, v_out, v_out, v_out, v_a, vl);
    w -= vl;
    src_y += vl;
    dst_argb += vl * 4;
  } while (w > 0);
}

void J400ToARGBRow_RVV(const uint8_t* src_y, uint8_t* dst_argb, int width) {
  size_t w = (size_t)width;
  size_t vl = __riscv_vsetvl_e8m2(w);
  vuint8m2_t v_a = __riscv_vmv_v_x_u8m2(255u, vl);
  do {
    vuint8m2_t v_y;
    v_y = __riscv_vle8_v_u8m2(src_y, vl);
    __riscv_vsseg4e8_v_u8m2(dst_argb, v_y, v_y, v_y, v_a, vl);
    w -= vl;
    src_y += vl;
    dst_argb += vl * 4;
    vl = __riscv_vsetvl_e8m2(w);
  } while (w > 0);
}

void SplitRGBRow_RVV(const uint8_t* src_rgb,
                     uint8_t* dst_r,
                     uint8_t* dst_g,
                     uint8_t* dst_b,
                     int width) {
  size_t w = (size_t)width;
  do {
    vuint8m2_t v_b, v_g, v_r;
    size_t vl = __riscv_vsetvl_e8m2(w);
    __riscv_vlseg3e8_v_u8m2(&v_r, &v_g, &v_b, src_rgb, vl);
    __riscv_vse8_v_u8m2(dst_r, v_r, vl);
    __riscv_vse8_v_u8m2(dst_g, v_g, vl);
    __riscv_vse8_v_u8m2(dst_b, v_b, vl);
    w -= vl;
    dst_r += vl;
    dst_g += vl;
    dst_b += vl;
    src_rgb += vl * 3;
  } while (w > 0);
}

void MergeRGBRow_RVV(const uint8_t* src_r,
                     const uint8_t* src_g,
                     const uint8_t* src_b,
                     uint8_t* dst_rgb,
                     int width) {
  size_t w = (size_t)width;
  do {
    size_t vl = __riscv_vsetvl_e8m2(w);
    vuint8m2_t v_r = __riscv_vle8_v_u8m2(src_r, vl);
    vuint8m2_t v_g = __riscv_vle8_v_u8m2(src_g, vl);
    vuint8m2_t v_b = __riscv_vle8_v_u8m2(src_b, vl);
    __riscv_vsseg3e8_v_u8m2(dst_rgb, v_r, v_g, v_b, vl);
    w -= vl;
    src_r += vl;
    src_g += vl;
    src_b += vl;
    dst_rgb += vl * 3;
  } while (w > 0);
}

void SplitARGBRow_RVV(const uint8_t* src_argb,
                      uint8_t* dst_r,
                      uint8_t* dst_g,
                      uint8_t* dst_b,
                      uint8_t* dst_a,
                      int width) {
  size_t w = (size_t)width;
  do {
    vuint8m2_t v_b, v_g, v_r, v_a;
    size_t vl = __riscv_vsetvl_e8m2(w);
    __riscv_vlseg4e8_v_u8m2(&v_b, &v_g, &v_r, &v_a, src_argb, vl);
    __riscv_vse8_v_u8m2(dst_a, v_a, vl);
    __riscv_vse8_v_u8m2(dst_r, v_r, vl);
    __riscv_vse8_v_u8m2(dst_g, v_g, vl);
    __riscv_vse8_v_u8m2(dst_b, v_b, vl);
    w -= vl;
    dst_a += vl;
    dst_r += vl;
    dst_g += vl;
    dst_b += vl;
    src_argb += vl * 4;
  } while (w > 0);
}

void MergeARGBRow_RVV(const uint8_t* src_r,
                      const uint8_t* src_g,
                      const uint8_t* src_b,
                      const uint8_t* src_a,
                      uint8_t* dst_argb,
                      int width) {
  size_t w = (size_t)width;
  do {
    size_t vl = __riscv_vsetvl_e8m2(w);
    vuint8m2_t v_r = __riscv_vle8_v_u8m2(src_r, vl);
    vuint8m2_t v_g = __riscv_vle8_v_u8m2(src_g, vl);
    vuint8m2_t v_b = __riscv_vle8_v_u8m2(src_b, vl);
    vuint8m2_t v_a = __riscv_vle8_v_u8m2(src_a, vl);
    __riscv_vsseg4e8_v_u8m2(dst_argb, v_b, v_g, v_r, v_a, vl);
    w -= vl;
    src_r += vl;
    src_g += vl;
    src_b += vl;
    src_a += vl;
    dst_argb += vl * 4;
  } while (w > 0);
}

void SplitXRGBRow_RVV(const uint8_t* src_argb,
                      uint8_t* dst_r,
                      uint8_t* dst_g,
                      uint8_t* dst_b,
                      int width) {
  size_t w = (size_t)width;
  do {
    vuint8m2_t v_b, v_g, v_r, v_a;
    size_t vl = __riscv_vsetvl_e8m2(w);
    __riscv_vlseg4e8_v_u8m2(&v_b, &v_g, &v_r, &v_a, src_argb, vl);
    __riscv_vse8_v_u8m2(dst_r, v_r, vl);
    __riscv_vse8_v_u8m2(dst_g, v_g, vl);
    __riscv_vse8_v_u8m2(dst_b, v_b, vl);
    w -= vl;
    dst_r += vl;
    dst_g += vl;
    dst_b += vl;
    src_argb += vl * 4;
  } while (w > 0);
}

void MergeXRGBRow_RVV(const uint8_t* src_r,
                      const uint8_t* src_g,
                      const uint8_t* src_b,
                      uint8_t* dst_argb,
                      int width) {
  size_t w = (size_t)width;
  size_t vl = __riscv_vsetvl_e8m2(w);
  vuint8m2_t v_a = __riscv_vmv_v_x_u8m2(255u, vl);
  do {
    vuint8m2_t v_r, v_g, v_b;
    v_r = __riscv_vle8_v_u8m2(src_r, vl);
    v_g = __riscv_vle8_v_u8m2(src_g, vl);
    v_b = __riscv_vle8_v_u8m2(src_b, vl);
    __riscv_vsseg4e8_v_u8m2(dst_argb, v_b, v_g, v_r, v_a, vl);
    w -= vl;
    src_r += vl;
    src_g += vl;
    src_b += vl;
    dst_argb += vl * 4;
    vl = __riscv_vsetvl_e8m2(w);
  } while (w > 0);
}

struct RgbConstants {
  uint8_t kRGBToY[4];
  uint16_t kAddY;
  uint16_t pad;
};

// RGB to JPeg coefficients
// B * 0.1140 coefficient = 29
// G * 0.5870 coefficient = 150
// R * 0.2990 coefficient = 77
// Add 0.5 = 0x80
static const struct RgbConstants kRgb24JPEGConstants = {{29, 150, 77, 0},
                                                        128,
                                                        0};

static const struct RgbConstants kRawJPEGConstants = {{77, 150, 29, 0}, 128, 0};

// RGB to BT.601 coefficients
// B * 0.1016 coefficient = 25
// G * 0.5078 coefficient = 129
// R * 0.2578 coefficient = 66
// Add 16.5 = 0x1080

static const struct RgbConstants kRgb24I601Constants = {{25, 129, 66, 0},
                                                        0x1080,
                                                        0};

static const struct RgbConstants kRawI601Constants = {{66, 129, 25, 0},
                                                      0x1080,
                                                      0};

// ARGB expects first 3 values to contain RGB and 4th value is ignored.
void ARGBToYMatrixRow_RVV(const uint8_t* src_argb,
                          uint8_t* dst_y,
                          int width,
                          const struct RgbConstants* rgbconstants) {
  assert(width != 0);
  size_t w = (size_t)width;
  vuint8m2_t v_by, v_gy, v_ry;  // vectors are to store RGBToY constant
  vuint16m4_t v_addy;           // vector is to store kAddY
  size_t vl = __riscv_vsetvl_e8m2(w);
  v_by = __riscv_vmv_v_x_u8m2(rgbconstants->kRGBToY[0], vl);
  v_gy = __riscv_vmv_v_x_u8m2(rgbconstants->kRGBToY[1], vl);
  v_ry = __riscv_vmv_v_x_u8m2(rgbconstants->kRGBToY[2], vl);
  v_addy = __riscv_vmv_v_x_u16m4(rgbconstants->kAddY, vl);
  do {
    vuint8m2_t v_b, v_g, v_r, v_a, v_y;
    vuint16m4_t v_y_u16;
    size_t vl = __riscv_vsetvl_e8m2(w);
    __riscv_vlseg4e8_v_u8m2(&v_b, &v_g, &v_r, &v_a, src_argb, vl);
    v_y_u16 = __riscv_vwmulu_vv_u16m4(v_r, v_ry, vl);
    v_y_u16 = __riscv_vwmaccu_vv_u16m4(v_y_u16, v_gy, v_g, vl);
    v_y_u16 = __riscv_vwmaccu_vv_u16m4(v_y_u16, v_by, v_b, vl);
    v_y_u16 = __riscv_vadd_vv_u16m4(v_y_u16, v_addy, vl);
    v_y = __riscv_vnsrl_wx_u8m2(v_y_u16, 8, vl);
    __riscv_vse8_v_u8m2(dst_y, v_y, vl);
    w -= vl;
    src_argb += 4 * vl;
    dst_y += vl;
  } while (w > 0);
}

void ARGBToYRow_RVV(const uint8_t* src_argb, uint8_t* dst_y, int width) {
  ARGBToYMatrixRow_RVV(src_argb, dst_y, width, &kRgb24I601Constants);
}

void ARGBToYJRow_RVV(const uint8_t* src_argb, uint8_t* dst_yj, int width) {
  ARGBToYMatrixRow_RVV(src_argb, dst_yj, width, &kRgb24JPEGConstants);
}

void ABGRToYRow_RVV(const uint8_t* src_abgr, uint8_t* dst_y, int width) {
  ARGBToYMatrixRow_RVV(src_abgr, dst_y, width, &kRawI601Constants);
}

void ABGRToYJRow_RVV(const uint8_t* src_abgr, uint8_t* dst_yj, int width) {
  ARGBToYMatrixRow_RVV(src_abgr, dst_yj, width, &kRawJPEGConstants);
}

// RGBA expects first value to be A and ignored, then 3 values to contain RGB.
void RGBAToYMatrixRow_RVV(const uint8_t* src_rgba,
                          uint8_t* dst_y,
                          int width,
                          const struct RgbConstants* rgbconstants) {
  assert(width != 0);
  size_t w = (size_t)width;
  vuint8m2_t v_by, v_gy, v_ry;  // vectors are to store RGBToY constant
  vuint16m4_t v_addy;           // vector is to store kAddY
  size_t vl = __riscv_vsetvl_e8m2(w);
  v_by = __riscv_vmv_v_x_u8m2(rgbconstants->kRGBToY[0], vl);
  v_gy = __riscv_vmv_v_x_u8m2(rgbconstants->kRGBToY[1], vl);
  v_ry = __riscv_vmv_v_x_u8m2(rgbconstants->kRGBToY[2], vl);
  v_addy = __riscv_vmv_v_x_u16m4(rgbconstants->kAddY, vl);
  do {
    vuint8m2_t v_b, v_g, v_r, v_a, v_y;
    vuint16m4_t v_y_u16;
    size_t vl = __riscv_vsetvl_e8m2(w);
    __riscv_vlseg4e8_v_u8m2(&v_a, &v_b, &v_g, &v_r, src_rgba, vl);
    v_y_u16 = __riscv_vwmulu_vv_u16m4(v_r, v_ry, vl);
    v_y_u16 = __riscv_vwmaccu_vv_u16m4(v_y_u16, v_gy, v_g, vl);
    v_y_u16 = __riscv_vwmaccu_vv_u16m4(v_y_u16, v_by, v_b, vl);
    v_y_u16 = __riscv_vadd_vv_u16m4(v_y_u16, v_addy, vl);
    v_y = __riscv_vnsrl_wx_u8m2(v_y_u16, 8, vl);
    __riscv_vse8_v_u8m2(dst_y, v_y, vl);
    w -= vl;
    src_rgba += 4 * vl;
    dst_y += vl;
  } while (w > 0);
}

void RGBAToYRow_RVV(const uint8_t* src_rgba, uint8_t* dst_y, int width) {
  RGBAToYMatrixRow_RVV(src_rgba, dst_y, width, &kRgb24I601Constants);
}

void RGBAToYJRow_RVV(const uint8_t* src_rgba, uint8_t* dst_yj, int width) {
  RGBAToYMatrixRow_RVV(src_rgba, dst_yj, width, &kRgb24JPEGConstants);
}

void BGRAToYRow_RVV(const uint8_t* src_bgra, uint8_t* dst_y, int width) {
  RGBAToYMatrixRow_RVV(src_bgra, dst_y, width, &kRawI601Constants);
}

void RGBToYMatrixRow_RVV(const uint8_t* src_rgb,
                         uint8_t* dst_y,
                         int width,
                         const struct RgbConstants* rgbconstants) {
  assert(width != 0);
  size_t w = (size_t)width;
  vuint8m2_t v_by, v_gy, v_ry;  // vectors are to store RGBToY constant
  vuint16m4_t v_addy;           // vector is to store kAddY
  size_t vl = __riscv_vsetvl_e8m2(w);
  v_by = __riscv_vmv_v_x_u8m2(rgbconstants->kRGBToY[0], vl);
  v_gy = __riscv_vmv_v_x_u8m2(rgbconstants->kRGBToY[1], vl);
  v_ry = __riscv_vmv_v_x_u8m2(rgbconstants->kRGBToY[2], vl);
  v_addy = __riscv_vmv_v_x_u16m4(rgbconstants->kAddY, vl);
  do {
    vuint8m2_t v_b, v_g, v_r, v_y;
    vuint16m4_t v_y_u16;
    size_t vl = __riscv_vsetvl_e8m2(w);
    __riscv_vlseg3e8_v_u8m2(&v_b, &v_g, &v_r, src_rgb, vl);
    v_y_u16 = __riscv_vwmulu_vv_u16m4(v_r, v_ry, vl);
    v_y_u16 = __riscv_vwmaccu_vv_u16m4(v_y_u16, v_gy, v_g, vl);
    v_y_u16 = __riscv_vwmaccu_vv_u16m4(v_y_u16, v_by, v_b, vl);
    v_y_u16 = __riscv_vadd_vv_u16m4(v_y_u16, v_addy, vl);
    v_y = __riscv_vnsrl_wx_u8m2(v_y_u16, 8, vl);
    __riscv_vse8_v_u8m2(dst_y, v_y, vl);
    w -= vl;
    src_rgb += 3 * vl;
    dst_y += vl;
  } while (w > 0);
}

void RGB24ToYJRow_RVV(const uint8_t* src_rgb24, uint8_t* dst_yj, int width) {
  RGBToYMatrixRow_RVV(src_rgb24, dst_yj, width, &kRgb24JPEGConstants);
}

void RAWToYJRow_RVV(const uint8_t* src_raw, uint8_t* dst_yj, int width) {
  RGBToYMatrixRow_RVV(src_raw, dst_yj, width, &kRawJPEGConstants);
}

void RGB24ToYRow_RVV(const uint8_t* src_rgb24, uint8_t* dst_y, int width) {
  RGBToYMatrixRow_RVV(src_rgb24, dst_y, width, &kRgb24I601Constants);
}

void RAWToYRow_RVV(const uint8_t* src_raw, uint8_t* dst_y, int width) {
  RGBToYMatrixRow_RVV(src_raw, dst_y, width, &kRawI601Constants);
}

void ARGBAttenuateRow_RVV(const uint8_t* src_argb,
                          uint8_t* dst_argb,
                          int width) {
  size_t w = (size_t)width;
  // To match behavior on other platforms, vxrm (fixed-point rounding mode
  // register) is set to round-to-nearest-up(0).
  asm volatile("csrwi vxrm, 0");
  do {
    vuint8m2_t v_b, v_g, v_r, v_a;
    vuint16m4_t v_ba_16, v_ga_16, v_ra_16;
    size_t vl = __riscv_vsetvl_e8m2(w);
    __riscv_vlseg4e8_v_u8m2(&v_b, &v_g, &v_r, &v_a, src_argb, vl);
    v_ba_16 = __riscv_vwmulu_vv_u16m4(v_b, v_a, vl);
    v_ga_16 = __riscv_vwmulu_vv_u16m4(v_g, v_a, vl);
    v_ra_16 = __riscv_vwmulu_vv_u16m4(v_r, v_a, vl);
    v_b = __riscv_vnclipu_wx_u8m2(v_ba_16, 8, vl);
    v_g = __riscv_vnclipu_wx_u8m2(v_ga_16, 8, vl);
    v_r = __riscv_vnclipu_wx_u8m2(v_ra_16, 8, vl);
    __riscv_vsseg4e8_v_u8m2(dst_argb, v_b, v_g, v_r, v_a, vl);
    w -= vl;
    src_argb += vl * 4;
    dst_argb += vl * 4;
  } while (w > 0);
}

#ifdef __cplusplus
}  // extern "C"
}  // namespace libyuv
#endif

#endif  // !defined(LIBYUV_DISABLE_RVV) && defined(__riscv_vector)
