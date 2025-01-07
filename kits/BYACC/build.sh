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
BYACC_SRC_PATH=${SHELL_PATH}/byacc-20230521/

#检查是否已经创建。
if [ ! -f ${TARGET_PERFIX_PATH}/bin/yacc ] ;then
{
    #临时目录。
    BUILD_TMP_PATH=${BUILD_PATH}/byacc/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/
    #复制源码到临时目录。
    cp -rf ${BYACC_SRC_PATH}/* ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/

    #给配置工具增加执行权限。
    chmod +0500 configure

    #执行配置。
    if [ "${TARGET_PLATFORM}" == "aarch64" ];then
        TARGET_MAKEFILE_CONF="--host=aarch64"
    elif [ "${TARGET_PLATFORM}" == "arm" ];then
        TARGET_MAKEFILE_CONF="--host=arm"
    else
        TARGET_MAKEFILE_CONF="--host=x86_64"
    fi

    #执行配置。
    ./configure \
        ${TARGET_MAKEFILE_CONF} \
        --prefix=${TARGET_PERFIX_PATH}/ \
        CC=${TARGET_COMPILER_C} \
        CFLAGS="-O3 -fPIC" \
        CXX=${TARGET_COMPILER_CXX} \
        CXXFLAGS="-O3 -fPIC" \
        AR=${TARGET_COMPILER_AR} \
        RANLIB=${TARGET_COMPILER_RANLIB}
    exit_if_error $? "byacc配置错误。" 1

    #编译。
    make
    exit_if_error $? "byacc编译错误。" 1

    #安装。
    make install 
    exit_if_error $? "byacc安装错误。" 1

    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi
