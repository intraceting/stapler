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
X264_SRC_PATH=${SHELL_PATH}/libvpx-1.13.0/

#检查是否已经创建。
if [ ! -f ${STAPLER_TARGET_PREFIX_PATH}/lib/libvpx.so ];then
{
    #临时目录。
    BUILD_TMP_PATH=${STAPLER_BUILD_PATH}/libvpx/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/
    #复制源码到临时目录。
    cp -rf ${X264_SRC_PATH}/* ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/

    #给配置工具增加执行权限。
    #chmod +0500 autogen.sh
    chmod +0500 configure
    
    #
   # ./autogen.sh
   # exit_if_error $? "autogen配置错误。" 1


  
    #执行配置。
    if [ "${STAPLER_TARGET_PLATFORM}" == "aarch64" ];then
        TARGET_MAKEFILE_CONF="--target=arm64-linux-gcc"
    elif [ "${STAPLER_TARGET_PLATFORM}" == "arm" ];then
        TARGET_MAKEFILE_CONF="--target=armv7-linux-gcc"
    else
        TARGET_MAKEFILE_CONF="--target=x86_64-linux-gcc"
    fi

    #
    export CC=${STAPLER_TARGET_COMPILER_PREFIX}gcc
    export CXX=${STAPLER_TARGET_COMPILER_PREFIX}g++
    export LD=$(${CC} "-print-prog-name=ld" 2>>/dev/null)
    export AR=$(${CC} "-print-prog-name=ar" 2>>/dev/null)
    export AS=$(${CC} "-print-prog-name=as" 2>>/dev/null)
    export STRIP=$(${CC} "-print-prog-name=strip" 2>>/dev/null)

    #执行配置。
    ./configure \
        ${TARGET_MAKEFILE_CONF} \
        --prefix=${STAPLER_TARGET_PREFIX_PATH}/ \
        --extra-cflags="-O3 -fPIC" \
        --enable-pic \
        --disable-examples \
        --disable-unit-tests \
        --enable-shared \
        --enable-static \
        --enable-libyuv \
        --enable-vp8 \
        --enable-vp9 
    exit_if_error $? "libvpx配置错误。" 1

    #编译。
    make -s -j4
    exit_if_error $? "libvpx编译错误。" 1

     #安装。
    make install 
    exit_if_error $? "libvpx安装错误。" 1


    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi
