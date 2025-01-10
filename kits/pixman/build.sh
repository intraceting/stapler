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
PIXMAN_SRC_PATH=${SHELL_PATH}/pixman-0.42.2/

#检查是否已经创建。
if [ ! -f ${TARGET_PREFIX_PATH}/lib/libpixman-1.a ] && [ ! -f ${TARGET_PREFIX_PATH}/lib/libpixman-1.so ] ;then
{
    #临时目录。
    BUILD_TMP_PATH=${BUILD_PATH}/pixman/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/
    #复制源码到临时目录。
    cp -rf ${PIXMAN_SRC_PATH}/* ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/

    #给配置工具增加执行权限。
    chmod +0500 configure

    #执行配置。
    if [ "${TARGET_PLATFORM}" == "aarch64" ];then
        TARGET_MAKEFILE_CONF="--host=aarch64"
    elif [ "${TARGET_PLATFORM}" == "arm" ];then
        TARGET_MAKEFILE_CONF="--host=armv7"
    else
        TARGET_MAKEFILE_CONF="--host=x86_64"
    fi
   
    #
    autoreconf -ivf -W cross
    exit_if_error $? "autoreconf配置错误。" 1

    #执行配置。
    ./configure ${TARGET_MAKEFILE_CONF} \
        --prefix=${TARGET_PREFIX_PATH}/ \
        CC=${TARGET_COMPILER_C} \
        AR=${TARGET_COMPILER_AR} \
        LD=${TARGET_COMPILER_LD} \
        "CFLAGS=-O3 -fPIC" \
        CXX=${TARGET_COMPILER_CXX} \
        "CXXFLAGS=-O3 -fPIC" \
        --enable-libpng=no
    exit_if_error $? "pixman配置错误。" 1

    #编译。
    make -j1
    exit_if_error $? "pixman编译错误。" 1

    #安装。
    make install 
    exit_if_error $? "pixman安装错误。" 1

    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi
