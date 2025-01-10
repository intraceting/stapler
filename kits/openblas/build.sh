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
OPENBLAS_SRC_PATH=${SHELL_PATH}/OpenBLAS-0.3.23/

#检查是否已经创建。
if [ ! -f ${TARGET_PREFIX_PATH}/lib/libopenblas.so ];then
{
    #临时目录。
    BUILD_TMP_PATH=${BUILD_PATH}/openblas/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/
    #复制源码到临时目录。
    cp -rf ${OPENBLAS_SRC_PATH}/* ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/


    #执行配置。
    if [ "${TARGET_PLATFORM}" == "aarch64" ];then
        TARGET_MAKEFILE_CONF="TARGET=ARMV8"
    elif [ "${TARGET_PLATFORM}" == "arm" ] ;then
        TARGET_MAKEFILE_CONF="TARGET=ARMV7"
    else
        TARGET_MAKEFILE_CONF=""
    fi

    #编译。
    make -s -j4 shared ${TARGET_MAKEFILE_CONF} \
        PREFIX="${TARGET_PREFIX_PATH}/" \
        HOSTCC="${NATIVE_COMPILER_C}" \
        CC="${TARGET_COMPILER_C}" \
        AR="${TARGET_COMPILER_AR}" \
        FC="${TARGET_COMPILER_FORTRAN}"
    exit_if_error $? "openblas编译错误。" 1

    #安装。
    make install ${TARGET_MAKEFILE_CONF} \
        PREFIX="${TARGET_PREFIX_PATH}/" \
        HOSTCC="${NATIVE_COMPILER_C}" \
        CC="${TARGET_COMPILER_C}" \
        AR="${TARGET_COMPILER_AR}" \
        FC="${TARGET_COMPILER_FORTRAN}"
    exit_if_error $? "openblas安装错误。" 1
        

    #恢复工作目录。
    cd ${SHELL_PATH}

}
fi