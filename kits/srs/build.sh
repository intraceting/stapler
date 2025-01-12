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
SRS_SRC_PATH=${SHELL_PATH}/srs-6.0.48/

#检查是否已经创建。
if [ ! -f ${STAPLER_TARGET_PREFIX_PATH}/objs/srs ] ;then
{
    #临时目录。
    BUILD_TMP_PATH=${STAPLER_BUILD_PATH}/srs/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/
    #复制源码到临时目录。
    cp -rf ${SRS_SRC_PATH}/* ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/trunk

    #给配置工具增加执行权限。
    chmod +0500 configure

    #执行配置。
    if [ "${STAPLER_TARGET_PLATFORM}" == "aarch64" ];then
        TARGET_MAKEFILE_CONF="--arch=aarch64 --cross-build"
    elif [ "${STAPLER_TARGET_PLATFORM}" == "arm" ];then
        TARGET_MAKEFILE_CONF="--arch=armv7 --cross-build"
    else
        TARGET_MAKEFILE_CONF="--arch=x86_64"
    fi

    #执行配置。
    ./configure ${TARGET_MAKEFILE_CONF} \
        --prefix=${STAPLER_TARGET_PREFIX_PATH}/ \
        --host=${STAPLER_TARGET_MACHINE} \
        --cross-prefix=${STAPLER_TARGET_COMPILER_PREFIX} \
        --cc=${STAPLER_TARGET_COMPILER_C} \
        --cxx=${STAPLER_TARGET_COMPILER_CXX} \
        --ar=${STAPLER_TARGET_COMPILER_AR} \
        --ld=${STAPLER_TARGET_COMPILER_LD} \
        --randlib=${STAPLER_TARGET_COMPILER_RANLIB} \
        --extra-flags="-L${STAPLER_TARGET_PREFIX_PATH}/lib/ -I${STAPLER_TARGET_PREFIX_PATH}/include/" \
        --jobs=6 \
        --srt=off \
        --rtc=off \
        --h265=on \
        --sys-ssl=off \
        --shared-srt=on \
        --shared-ffmpeg=on \
        --srt=off \
        --nasm=off \
        --srtp-nasm=off \
        --ffmpeg-fit=off \
        --ffmpeg-opus=off
    exit_if_error $? "srs配置错误。" 1

    #编译。
    make
    exit_if_error $? "srs编译错误。" 1

    #安装。
    make install 
    exit_if_error $? "srs安装错误。" 1

    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi