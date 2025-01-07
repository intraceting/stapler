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
GDB_SRC_PATH=${SHELL_PATH}/gdb-8.2.1/

#检查是否已经创建。
if [ ! -f ${TARGET_PERFIX_PATH}/bin/gdb ];then
{
    #临时目录。
    BUILD_TMP_PATH=${BUILD_PATH}/gdb/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/
    #复制源码到临时目录。
    cp -rf ${GDB_SRC_PATH}/* ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/

    #
    autoreconf -ivf -W cross
    exit_if_error $? "autoreconf配置错误。" 1

    #执行配置。
    if [ "${TARGET_PLATFORM}" == "aarch64" ];then
        TARGET_MAKEFILE_CONF="--host=aarch64-linux"
    elif [ "${TARGET_PLATFORM}" == "arm" ];then
        TARGET_MAKEFILE_CONF="--host=armv7-linux"
    else
        TARGET_MAKEFILE_CONF="--host=x86_64-linux"
    fi

    #追加公共配置。
    TARGET_MAKEFILE_CONF="${TARGET_MAKEFILE_CONF} --prefix=${TARGET_PERFIX_PATH}/"
    TARGET_MAKEFILE_CONF="${TARGET_MAKEFILE_CONF} CC=${TARGET_COMPILER_C}"
    TARGET_MAKEFILE_CONF="${TARGET_MAKEFILE_CONF} AR=${TARGET_COMPILER_AR}"
    TARGET_MAKEFILE_CONF="${TARGET_MAKEFILE_CONF} LD=${TARGET_COMPILER_LD}"
    TARGET_MAKEFILE_CONF="${TARGET_MAKEFILE_CONF} CFLAGS=-O3"
    TARGET_MAKEFILE_CONF="${TARGET_MAKEFILE_CONF} CXX=${TARGET_COMPILER_CXX}"
    TARGET_MAKEFILE_CONF="${TARGET_MAKEFILE_CONF} CXXFLAGS=-O3"

    #执行配置。
    ./configure ${TARGET_MAKEFILE_CONF}
    exit_if_error $? "gdb配置错误。" 1

    #编译。
    make -s -j4
    exit_if_error $? "gdb编译错误。" 1

    #安装。
    make install 
    exit_if_error $? "gdb安装错误。" 1

    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi
