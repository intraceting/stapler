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
OPENSSH_SRC_PATH=${SHELL_PATH}/openssh-8.2p1/

#检查是否已经创建。
if [ ! -f ${STAPLER_TARGET_PREFIX_PATH}/sbin/sshd ];then
{
    #临时目录。
    BUILD_TMP_PATH=${STAPLER_BUILD_PATH}/openssh/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/
    #复制源码到临时目录。
    cp -rf ${OPENSSH_SRC_PATH}/* ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/

    #
    autoreconf -ivf -W cross
    exit_if_error $? "autoreconf配置错误。" 1

    #执行配置。
    if [ "${STAPLER_TARGET_PLATFORM}" == "aarch64" ];then
        TARGET_MAKEFILE_CONF="--host=aarch64-linux"
    elif [ "${STAPLER_TARGET_PLATFORM}" == "arm" ];then
        TARGET_MAKEFILE_CONF="--host=armv7-linux"
    else
        TARGET_MAKEFILE_CONF="--host=x86_64-linux"
    fi

    #执行配置。
    ./configure ${TARGET_MAKEFILE_CONF} \
        --prefix="${STAPLER_TARGET_PREFIX_PATH}/" \
        CC="${STAPLER_TARGET_COMPILER_C}" \
        AR="${STAPLER_TARGET_COMPILER_AR}" \
        LD="${STAPLER_TARGET_COMPILER_LD}" \
        CFLAGS="-O3" \
        CXX="${STAPLER_TARGET_COMPILER_CXX}" \
        CXXFLAGS="-O3" \
        --with-zlib="${STAPLER_TARGET_PREFIX_PATH}" \
        --without-zlib-version-check \
        --with-ssl-dir="${STAPLER_TARGET_PREFIX_PATH}" \
        --without-openssl-header-check \
        --disable-etc-default-login \
        --disable-strip \
        --with-privsep-path="${STAPLER_TARGET_PREFIX_PATH}/var/empty"
    exit_if_error $? "openssh配置错误。" 1

    #编译。
    make -s -j4
    exit_if_error $? "openssh编译错误。" 1

    #安装。
    make install-nokeys 
    exit_if_error $? "openssh安装错误。" 1

    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi
