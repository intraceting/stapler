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
OPENSSL_SRC_PATH=${SHELL_PATH}/openssl-1.1.1s/

#检查是否已经创建。
if [ ! -f ${TARGET_PERFIX_PATH}/lib/libssl.so ];then
{
    #临时目录。
    BUILD_TMP_PATH=${BUILD_PATH}/openssl/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/
    #复制源码到临时目录。
    cp -rf ${OPENSSL_SRC_PATH}/* ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/

    #执行配置。
    if [ "${TARGET_PLATFORM}" == "aarch64" ];then
        ${OPENSSL_SRC_PATH}/Configure --prefix=${TARGET_PERFIX_PATH}/ --cross-compile-prefix=${TARGET_COMPILER_PREFIX} linux-aarch64 
    elif [ "${TARGET_PLATFORM}" == "arm" ] ;then
        ${OPENSSL_SRC_PATH}/Configure --prefix=${TARGET_PERFIX_PATH}/ --cross-compile-prefix=${TARGET_COMPILER_PREFIX} linux-armv4
    else
        ${OPENSSL_SRC_PATH}/Configure --prefix=${TARGET_PERFIX_PATH}/ --cross-compile-prefix=${TARGET_COMPILER_PREFIX} linux-x86_64
    fi
    exit_if_error $? "openssl配置错误。" 1


    #编译。
    make -s -j4
    exit_if_error $? "openssl编译错误。" 1
    
    #安装。
    make install 
    exit_if_error $? "openssl安装错误。" 1


    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi