#!/bin/bash
#
# Copyright (c) 2021 The STAPLER project authors. All Rights Reserved.
#

#
SHELL_PATH=$(realpath $(cd `dirname $0`; pwd))

#
exit_if_error()
#errno
#errstr
#exitcode
#buildpath
{
    if [ $# -ne 3 ];then
    {
        echo "需要三个参数，分别是：errno，errstr，exitcode。"
        exit 1
    }
    fi 
    
    if [ $1 -ne 0 ];then
    {
        echo $2
        exit $3
    }
    fi
}

#
OPENCV_SRC_PATH=${SHELL_PATH}//opencv-4.3.0/
OPENCV_CONTRIB_SRC_PATH=${SHELL_PATH}/opencv_contrib-4.3.0/

#检查是否已经创建。
if [ ! -f ${STAPLER_TARGET_PREFIX_PATH}/lib/libopencv_core.so ];then
{
    #临时目录。
    BUILD_TMP_PATH=${STAPLER_BUILD_PATH}/opencv/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/

    #执行配置。
    if [ "${STAPLER_TARGET_PLATFORM}" == "aarch64" ];then
        TARGET_TOOLCHAIN_FILE="${OPENCV_SRC_PATH}/platforms/linux/aarch64-gnu.toolchain.cmake -DAARCH64=ON"
    elif [ "${STAPLER_TARGET_PLATFORM}" == "arm" ] ;then
        TARGET_TOOLCHAIN_FILE="${OPENCV_SRC_PATH}/platforms/linux/arm-gnueabi.toolchain.cmake -DENABLE_NEON=ON -DARM=ON"
    else
        TARGET_TOOLCHAIN_FILE="${OPENCV_SRC_PATH}/platforms/linux/gnu.toolchain.cmake"
    fi
   
    #
    RAW_GITHUB_HOST="https://raw.githubusercontent.com"
    #RAW_GITHUB_HOST="https://raw.gitmirror.com"
   

    #执行配置。
    ${STAPLER_NATIVE_PREFIX_PATH}/bin/cmake ${OPENCV_SRC_PATH} \
        -DCMAKE_PREFIX_PATH=${STAPLER_TARGET_PREFIX_PATH}/ \
        -DCMAKE_INSTALL_PREFIX=${STAPLER_TARGET_PREFIX_PATH}/ \
        -DCMAKE_C_COMPILER=${STAPLER_TARGET_COMPILER_C} \
        -DCMAKE_CXX_COMPILER=${STAPLER_TARGET_COMPILER_CXX} \
        -DCMAKE_LINKER=${STAPLER_TARGET_COMPILER_LD} \
        -DCMAKE_AR=${STAPLER_TARGET_COMPILER_AR} \
        -DCMAKE_TOOLCHAIN_FILE=${TARGET_TOOLCHAIN_FILE}/ \
        -DCMAKE_FIND_ROOT_PATH=${STAPLER_TARGET_PREFIX_PATH}/ \
        -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
        -DCMAKE_EXE_LINKER_FLAGS="-Wl,-rpath-link,${STAPLER_TARGET_PREFIX_PATH}/lib" \
        -DCMAKE_C_FLAGS=-O3 \
        -DCMAKE_CXX_FLAGS=-O3 \
        -DCMAKE_BUILD_TYPE=Release \
        -D3RDPART_LIBS_DIR=${STAPLER_TARGET_PREFIX_PATH}/:${STAPLER_TARGET_COMPILER_SYSROOT} \
        -DOPENCV_EXTRA_MODULES_PATH=${OPENCV_CONTRIB_SRC_PATH}/modules \
        -DOPENCV_DOWNLOAD_PATH="${STAPLER_BUILD_PATH}/opencv.cache/" \
        -DOPENCV_BOOSTDESC_URL="${RAW_GITHUB_HOST}/opencv/opencv_3rdparty/34e4206aef44d50e6bbcd0ab06354b52e7466d26/" \
        -DOPENCV_VGGDESC_URL="${RAW_GITHUB_HOST}/opencv/opencv_3rdparty/fccf7cd6a4b12079f73bbfb21745f9babcd4eb1d/" \
        -DOPENCV_FACE_ALIGNMENT_URL="${RAW_GITHUB_HOST}/opencv/opencv_3rdparty/8afa57abc8229d611c4937165d20e2a2d9fc5a12/" \
        -DOPENCV_IPPICV_URL="${RAW_GITHUB_HOST}/opencv/opencv_3rdparty/a56b6ac6f030c312b2dce17430eef13aed9af274/ippicv/" \
        -DOPENCV_ENABLE_NONFREE=ON \
        -DOPENCV_ENABLE_PKG_CONFIG=ON \
        -DOPENCV_FFMPEG_SKIP_BUILD_CHECK=OFF \
        -DWITH_FFMPEG=OFF \
        -DWITH_1394=OFF \
        -DWITH_ADE=OFF \
        -DWITH_VTK=OFF \
        -DWITH_EIGEN=OFF \
        -DWITH_GSTREAMER=OFF \
        -DWITH_GSTREAMER_0_10=OFF \
        -DWITH_GTK=OFF \
        -DWITH_GTK_2_X=OFF \
        -DWITH_IPP=OFF \
        -DWITH_JASPER=ON \
        -DWITH_JPEG=ON \
        -DWITH_WEBP=OFF \
        -DWITH_OPENEXR=OFF \
        -DWITH_OPENGL=OFF \
        -DWITH_OPENVX=OFF \
        -DWITH_OPENNI=OFF \
        -DWITH_OPENNI2=OFF \
        -DWITH_PNG=ON \
        -DWITH_TBB=OFF \
        -DWITH_TIFF=ON \
        -DWITH_V4L=ON \
        -DWITH_OPENCL=OFF \
        -DWITH_OPENCL_SVM=OFF \
        -DWITH_OPENCLAMDFFT=OFF \
        -DWITH_OPENCLAMDBLAS=OFF \
        -DWITH_GPHOTO2=OFF \
        -DWITH_LAPACK=OFF \
        -DWITH_ITT=OFF \
        -DWITH_QUIRC=OFF \
        -DBUILD_PNG=ON \
        -DBUILD_TIFF=ON \
        -DBUILD_TBB=ON \
        -DBUILD_JPEG=ON \
        -DBUILD_JASPER=ON \
        -DBUILD_ZLIB=OFF \
        -DBUILD_EXAMPLES=OFF \
        -DBUILD_JAVA=OFF \
        -DBUILD_opencv_python=OFF \
        -DBUILD_opencv_hdf=OFF \
        -DBUILD_opencv_freetype=ON
    exit_if_error $? "opencv配置错误。" 1

    #编译。
    make -s -j4
    exit_if_error $? "opencv编译错误。" 1

    # #安装。
    make install 
    exit_if_error $? "opencv安装错误。" 1


    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi