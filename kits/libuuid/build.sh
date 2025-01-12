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
LIBUUID_SRC_PATH=${SHELL_PATH}/libuuid-1.0.3/

#检查是否已经创建。
if [ ! -f ${STAPLER_TARGET_PREFIX_PATH}/lib/libuuid.a ];then
{
    #临时目录。
    BUILD_TMP_PATH=${STAPLER_BUILD_PATH}/libuuid/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/
    #复制源码到临时目录。
    cp -rf ${LIBUUID_SRC_PATH}/* ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/

    #给配置工具增加执行权限。
    chmod +0500 configure
        
    #
    autoreconf -ivf -W cross
    exit_if_error $? "autoreconf配置错误。" 1

    #执行配置。
    if [ "${STAPLER_TARGET_PLATFORM}" == "aarch64" ];then
        ./configure --prefix=${STAPLER_TARGET_PREFIX_PATH}/ --host=aarch64 CC=${STAPLER_TARGET_COMPILER_C} CFLAGS="-O3 -DEOF=-1 -fPIC" CXX=${STAPLER_TARGET_COMPILER_CXX} CXXFLAGS="-O3 -DEOF=-1 -fPIC -fPIC"
    elif [ "${STAPLER_TARGET_PLATFORM}" == "arm" ] ;then
        ./configure --prefix=${STAPLER_TARGET_PREFIX_PATH}/ --host=arm CC=${STAPLER_TARGET_COMPILER_C} CFLAGS="-O3 -DEOF=-1 -fPIC"  CXX=${STAPLER_TARGET_COMPILER_CXX} CXXFLAGS="-O3 -DEOF=-1 -fPIC -fPIC"
    else
        ./configure --prefix=${STAPLER_TARGET_PREFIX_PATH}/ --host=x86_64 CC=${STAPLER_TARGET_COMPILER_C} CFLAGS="-O3 -DEOF=-1 -fPIC"  CXX=${STAPLER_TARGET_COMPILER_CXX} CXXFLAGS="-O3 -DEOF=-1 -fPIC -fPIC"
    fi


    #编译。
    make
    exit_if_error $? "libuuid编译错误。" 1

     #安装。
    make install 
    exit_if_error $? "libuuid安装错误。" 1


    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi
