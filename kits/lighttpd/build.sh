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
LIGHTTPD_SRC_PATH=${SHELL_PATH}/lighttpd-1.4.71/

#检查是否已经创建。
if [ ! -f ${TARGET_PERFIX_PATH}/sbin/lighttpd ];then
{
    #临时目录。
    BUILD_TMP_PATH=${BUILD_PATH}/lighttpd/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/

    #执行配置。
    ${NATIVE_PERFIX_PATH}/bin/cmake ${LIGHTTPD_SRC_PATH} \
        -DCMAKE_PREFIX_PATH=${TARGET_PERFIX_PATH}/ \
        -DCMAKE_INSTALL_PREFIX=${TARGET_PERFIX_PATH}/ \
        -DCMAKE_C_COMPILER=${TARGET_COMPILER_C} \
        -DCMAKE_CXX_COMPILER=${TARGET_COMPILER_CXX} \
        -DCMAKE_LINKER=${TARGET_COMPILER_LD} \
        -DCMAKE_AR=${TARGET_COMPILER_AR} \
        -DCMAKE_RANLIB=${TARGET_COMPILER_RANLIB} \
        -DCMAKE_FIND_ROOT_PATH=${TARGET_PERFIX_PATH}/ \
        -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
        -DCMAKE_SYSTEM_NAME=Generic \
        -DCMAKE_C_FLAGS="-O3 -I${TARGET_PERFIX_PATH}/include/ -L${TARGET_PERFIX_PATH}/lib" \
        -DCMAKE_CXX_FLAGS="-O3 -I${TARGET_PERFIX_PATH}/include/ -L${TARGET_PERFIX_PATH}/lib" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_STANDARD=11 \
        -DWITH_PCRE2=OFF \
        -DWITH_PCRE=OFF \
        -DWITH_ZLIB=ON \
        -DWITH_OPENSSL=ON
    exit_if_error $? "lighttpd配置错误。" 1

    #编译。
    make -j1
    exit_if_error $? "lighttpd编译错误。" 1

    # #安装。
    make install 
    exit_if_error $? "lighttpd安装错误。" 1


    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi