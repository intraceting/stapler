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
STB_SRC_PATH=${SHELL_PATH}/camport3-1.6.33/

#检查是否已经创建。
if [ ! -f ${STAPLER_TARGET_PREFIX_PATH}/include/TYApi.h ];then
{
    #创建安装目录。
    mkdir -p ${STAPLER_TARGET_PREFIX_PATH}/include/

    #不需要编译，直接复制文件到安装目录。

    #复掉include下的文件。
    cp -rf ${STB_SRC_PATH}/include/*.h ${STAPLER_TARGET_PREFIX_PATH}/include/

       #执行配置。
    if [ "${STAPLER_TARGET_PLATFORM}" == "aarch64" ];then
        cp -rf ${STB_SRC_PATH}/lib/linux/lib_Aarch64/lib* ${STAPLER_TARGET_PREFIX_PATH}/lib/
    elif [ "${TARGET_PLATFORM}" == "arm" ] ;then
        cp -rf ${STB_SRC_PATH}/lib/linux/lib_armv7hf/lib* ${STAPLER_TARGET_PREFIX_PATH}/lib/
    else
        cp -rf ${STB_SRC_PATH}/lib/linux/lib_x64/lib* ${STAPLER_TARGET_PREFIX_PATH}/lib/
    fi
}
fi