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
NASM_SRC_PATH=${SHELL_PATH}/nasm-2.15/

#检查是否已经创建。
if [ ! -f ${STAPLER_TARGET_PREFIX_PATH}/bin/nasm ];then
{
    #临时目录。
    BUILD_TMP_PATH=${STAPLER_BUILD_PATH}/nasm/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/
    #复制源码到临时目录。
    cp -rf ${NASM_SRC_PATH}/* ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/

    #给配置工具增加执行权限。
    chmod +0500 autogen.sh
    #chmod +0500 configure
    
    #
    ./autogen.sh
    exit_if_error $? "autogen配置错误。" 1

    #执行配置。
    if [ "${STAPLER_TARGET_PLATFORM}" == "aarch64" ];then
        TARGET_MAKEFILE_CONF="--host=aarch64"
    elif [ "${STAPLER_TARGET_PLATFORM}" == "arm" ];then
        TARGET_MAKEFILE_CONF="--host=armv7"
    else
        TARGET_MAKEFILE_CONF="--host=x86_64"
    fi

     #执行配置。
    ./configure \
        ${TARGET_MAKEFILE_CONF} \
        --prefix=${STAPLER_TARGET_PREFIX_PATH}/ \
        CC=${STAPLER_TARGET_COMPILER_C} \
        CFLAGS="-O3 -DEOF=-1 -fPIC" \
        CXX=${STAPLER_TARGET_COMPILER_CXX} \
        CXXFLAGS="-O3 -DEOF=-1 -fPIC"
    exit_if_error $? "nasm配置错误。" 1

    #编译。
    make -s -j4
    exit_if_error $? "nasm编译错误。" 1

     #安装。
    make install 
    exit_if_error $? "nasm安装错误。" 1


    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi
