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
    exit_if_error 1 "SOPA不支持此平台。" 0
elif [ "${TARGET_PLATFORM}" == "arm" ];then
    exit_if_error 1 "SOPA不支持此平台。" 0
else
    exit_if_error 0 "SOPA不支持此平台。" 0
fi

#
GSOAP_SRC_PATH=${SHELL_PATH}/gsoap_2.8.130/

#检查是否已经创建。
if [ ! -f ${TARGET_PREFIX_PATH}/bin/soapcpp2 ];then
{
    #临时目录。
    BUILD_TMP_PATH=${BUILD_PATH}/gsoap/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/
    #复制源码到临时目录。
    cp -rf ${GSOAP_SRC_PATH}/* ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/

    #给配置工具增加执行权限。
    chmod +0500 configure
    
    #
    autoreconf -ivf -W cross
    exit_if_error $? "autoreconf配置错误。" 1

    #执行配置。
    if [ "${TARGET_PLATFORM}" == "aarch64" ];then
        TARGET_MAKEFILE_CONF="--host=aarch64"
    elif [ "${TARGET_PLATFORM}" == "arm" ];then
        TARGET_MAKEFILE_CONF="--host=arm"
    else
        TARGET_MAKEFILE_CONF="--host=x86_64"
    fi

    # 强制生效 #define HAVE_MALLOC 1
    echo "ac_cv_func_malloc_0_nonnull=yes" > configure.tmp.cache

    #
    ./configure \
        ${TARGET_MAKEFILE_CONF} \
        --cache-file=./configure.tmp.cache \
        --prefix=${TARGET_PREFIX_PATH}/ \
        --with-zlib=${TARGET_PREFIX_PATH}/ \
        --with-openssl=${TARGET_PREFIX_PATH}/ \
        CC=${TARGET_COMPILER_C} \
        CFLAGS="-O3 -fPIC" \
        CXX=${TARGET_COMPILER_CXX} \
        CXXFLAGS="-O3 -fPIC" \
        AR=${TARGET_COMPILER_AR} \
        RANLIB=${TARGET_COMPILER_RANLIB}

    exit_if_error $? "gsoap配置错误。" 1

    #编译。
    make -s -j4
    exit_if_error $? "gsoap编译错误。" 1
    
    # if [ $? -ne 0 ];then
    # {
    #     #交叉编译无法执行，备份一下。
    #     mv ${BUILD_TMP_PATH}/gsoap/src/soapcpp2 ${BUILD_TMP_PATH}/gsoap/src/soapcpp2.back
    #     exit_if_error $? "gsoap编译错误。" 1

    #     #从本机环境复制一份。
    #     cp ${NATIVE_PREFIX_PATH}/bin/soapcpp2 ${BUILD_TMP_PATH}/gsoap/src/
    #     exit_if_error $? "gsoap编译错误。" 1

    #     #再次编译。
    #     make -s -j4
    #     exit_if_error $? "gsoap编译错误。" 1

    #     #备份恢复。
    #     mv -f ${BUILD_TMP_PATH}/gsoap/src/soapcpp2.back ${BUILD_TMP_PATH}/gsoap/src/soapcpp2
    #     exit_if_error $? "gsoap编译错误。" 1
    # }
    # fi

     #安装。
    make install 
    exit_if_error $? "gsoap安装错误。" 1


    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi
