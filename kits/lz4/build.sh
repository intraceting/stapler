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
LZ4_SRC_PATH=${SHELL_PATH}/lz4-1.9.4/

#检查是否已经创建。
if [ ! -f ${TARGET_PREFIX_PATH}/bin/lz4 ];then
{
    #临时目录。
    BUILD_TMP_PATH=${BUILD_PATH}/file/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/
    #复制源码到临时目录。
    cp -rf ${LZ4_SRC_PATH}/* ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/
   
    #编译。
    make lib CC=${TARGET_COMPILER_C} LD=${TARGET_COMPILER_LD} AR=${TARGET_COMPILER_AR} VERBOSE=1
    exit_if_error $? "lz4编译错误。" 1

    #安装。
    make install PREFIX=${TARGET_PREFIX_PATH}/ CC=${TARGET_COMPILER_C} LD=${TARGET_COMPILER_LD} AR=${TARGET_COMPILER_AR} VERBOSE=1
    exit_if_error $? "lz4安装错误。" 1

    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi
