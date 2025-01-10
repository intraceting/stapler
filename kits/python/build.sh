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
if [ "${TARGET_PLATFORM}" == "aarch64" ];then
    exit_if_error 1 "python不支持此平台。" 0
elif [ "${TARGET_PLATFORM}" == "arm" ];then
    exit_if_error 1 "python不支持此平台。" 0
else
    exit_if_error 1 "python不支持此平台。" 0
fi

#
PYTHON_SRC_PATH=${SHELL_PATH}/Python-3.11.5/

#检查是否已经创建。
if [ ! -f ${TARGET_PREFIX_PATH}/bin/python3.11 ] ;then
{
    #临时目录。
    BUILD_TMP_PATH=${BUILD_PATH}/python/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/
    #复制源码到临时目录。
    cp -rf ${PYTHON_SRC_PATH}/* ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/

    #给配置工具增加执行权限。
    chmod +0500 configure

    #执行配置。
    if [ "${TARGET_PLATFORM}" == "aarch64" ];then
        TARGET_MAKEFILE_CONF="--build=x86_64 --host=aarch64"
    elif [ "${TARGET_PLATFORM}" == "arm" ];then
        TARGET_MAKEFILE_CONF="--build=x86_64 --host=${TARGET_MACHINE} --target=${TARGET_MACHINE}"
    else
        TARGET_MAKEFILE_CONF="--build=x86_64 --host=x86_64"
    fi

    #执行配置。
    ./configure --prefix=${TARGET_PREFIX_PATH}/ --enable-optimizations --with-build-python=python ${TARGET_MAKEFILE_CONF} CC=${TARGET_COMPILER_C} 
    exit_if_error $? "python配置错误。" 1

    #编译。
    make -s -j4
    exit_if_error $? "python编译错误。" 1

    #安装。
    make install 
    exit_if_error $? "python安装错误。" 1

    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi
