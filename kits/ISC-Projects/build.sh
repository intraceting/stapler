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
if [ "${STAPLER_TARGET_PLATFORM}" == "aarch64" ];then
    exit_if_error 1 "DHCP不支持此平台。" 0
elif [ "${STAPLER_TARGET_PLATFORM}" == "arm" ];then
    exit_if_error 1 "DHCP不支持此平台。" 0
else
    exit_if_error 1 "DHCP不支持此平台。" 0
fi

#
DHCP_SRC_PATH=${SHELL_PATH}/dhcp-4_4_3/

#检查是否已经创建。
if [ ! -f ${STAPLER_TARGET_PREFIX_PATH}/sbin/dhclient ] ;then
{
    #临时目录。
    BUILD_TMP_PATH=${STAPLER_BUILD_PATH}/dhcp/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/
    #复制源码到临时目录。
    cp -rf ${DHCP_SRC_PATH}/. ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/

    #给配置工具增加执行权限。
    chmod +0500 configure

    #执行配置。
    if [ "${STAPLER_TARGET_PLATFORM}" == "aarch64" ];then
        TARGET_MAKEFILE_CONF="--host=aarch64"
    elif [ "${STAPLER_TARGET_PLATFORM}" == "arm" ];then
        TARGET_MAKEFILE_CONF="--host=armv7"
    else
        TARGET_MAKEFILE_CONF="--host=x86_64"
    fi
    
    #
    autoreconf -ivf -W cross
    exit_if_error $? "autoreconf配置错误。" 1

    #执行配置。
    ./configure ${TARGET_MAKEFILE_CONF} \
        --prefix=${STAPLER_TARGET_PREFIX_PATH}/ \
        --with-randomdev=no \
        --disable-dhcpv6 \
        "--with-bind-extra-config=${TARGET_MAKEFILE_CONF}"\
        BUILD_CC=${STAPLER_NATIVE_COMPILER_C} \
        CC=${STAPLER_TARGET_COMPILER_C} \
        AR=${STAPLER_TARGET_COMPILER_AR} \
        LD=${STAPLER_TARGET_COMPILER_LD} \
        "CFLAGS=-O3 -fPIC -I${STAPLER_TARGET_PREFIX_PATH}/include/" \
        "LDFLAGS=-L${STAPLER_TARGET_PREFIX_PATH}/lib/"
        
    exit_if_error $? "dhcp配置错误。" 1

    #编译。
    make
    exit_if_error $? "dhcp编译错误。" 1

    #安装。
    make install 
    exit_if_error $? "dhcp安装错误。" 1

    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi