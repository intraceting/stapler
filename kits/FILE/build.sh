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

#执行配置。
if [ "${STAPLER_TARGET_PLATFORM}" == "aarch64" ];then
    exit_if_error 1 "FILE不支持此平台。" 0
elif [ "${STAPLER_TARGET_PLATFORM}" == "arm" ];then
    exit_if_error 1 "FILE不支持此平台。" 0
else
    exit_if_error 0 "FILE不支持此平台。" 0
fi

#
FILE_SRC_PATH=${SHELL_PATH}/file-FILE5_44/

#检查是否已经创建。
if [ ! -f ${STAPLER_TARGET_PREFIX_PATH}/lib/libmagic.a ];then
{
    #临时目录。
    BUILD_TMP_PATH=${STAPLER_BUILD_PATH}/file/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/
    #复制源码到临时目录。
    cp -rf ${FILE_SRC_PATH}/* ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/



    #执行配置。
    if [ "${STAPLER_TARGET_PLATFORM}" == "aarch64" ];then
        TARGET_MAKEFILE_CONF="--host=aarch64"
    elif [ "${STAPLER_TARGET_PLATFORM}" == "arm" ];then
        TARGET_MAKEFILE_CONF="--host=armv7"
    else
        TARGET_MAKEFILE_CONF="--host=x86_64"
    fi

    #追加公共配置。
    TARGET_MAKEFILE_CONF="${TARGET_MAKEFILE_CONF} --prefix=${STAPLER_TARGET_PREFIX_PATH}/"
    TARGET_MAKEFILE_CONF="${TARGET_MAKEFILE_CONF} --disable-libtool-lock"
    TARGET_MAKEFILE_CONF="${TARGET_MAKEFILE_CONF} CC=${STAPLER_TARGET_COMPILER_C}"
    TARGET_MAKEFILE_CONF="${TARGET_MAKEFILE_CONF} AR=${STAPLER_TARGET_COMPILER_AR}"
    TARGET_MAKEFILE_CONF="${TARGET_MAKEFILE_CONF} LD=${STAPLER_TARGET_COMPILER_LD}"
    TARGET_MAKEFILE_CONF="${TARGET_MAKEFILE_CONF} CFLAGS=-O3"
    TARGET_MAKEFILE_CONF="${TARGET_MAKEFILE_CONF} CXX=${STAPLER_TARGET_COMPILER_CXX}"
    TARGET_MAKEFILE_CONF="${TARGET_MAKEFILE_CONF} CXXFLAGS=-O3"
    
    #
    autoreconf -ivf -W cross
    exit_if_error $? "autoreconf配置错误。" 1

    #执行配置。
    ./configure ${TARGET_MAKEFILE_CONF}
    exit_if_error $? "file配置错误。" 1

    #编译。
    make -s -j4
    exit_if_error $? "file编译错误。" 1

    #安装。
    make install 
    exit_if_error $? "file安装错误。" 1

    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi
