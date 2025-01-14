#!/bin/bash
#
# CopyRight (c) 2021 The STAPLER project authors. All Rights Reserved.
##
SHELLDIR=$(cd `dirname "$0"`; pwd)

#
exit_if_error()
#errno
#errstr
#exitcode
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
SRC_PATH=${SHELLDIR}/abcdk-2.0.1/

#检查是否已经创建。
if [ ! -f ${STAPLER_TARGET_PREFIX_PATH}/lib/libabcdk.so ];then
{
    #临时目录。
    BUILD_TMP_PATH=${STAPLER_BUILD_PATH}/abcdk/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/

    #执行配置。
    ${SRC_PATH}/configure.sh \
        -d "COMPILER_PREFIX=${STAPLER_TARGET_COMPILER_PREFIX}" \
        -d "BUILD_PATH=${BUILD_TMP_PATH}/" \
        -d "BUILD_PACKAGE_PATH=${BUILD_TMP_PATH}/" \
        -d "INSTALL_PREFIX=${STAPLER_TARGET_PREFIX_PATH}" \
        -d "THIRDPARTY_FIND_ROOT=${STAPLER_TARGET_PREFIX_PATH}" \
        -d "THIRDPARTY_FIND_MODE=only" \
        -d "THIRDPARTY_PACKAGES=openssl,ffmpeg,x264,x265,nghttp2,lz4"
    exit_if_error $? "abcdk配置错误。" 1

    #编译。
    make -s -j4 -C ${SRC_PATH} MAKE_CONF="${BUILD_TMP_PATH}/makefile.conf"
    exit_if_error $? "abcdk编译错误。" 1

    #安装。
    make -C ${SRC_PATH} MAKE_CONF="${BUILD_TMP_PATH}/makefile.conf" install 
    exit_if_error $? "abcdk安装错误。" 1
}
fi
