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
JSONCPP_SRC_PATH=${SHELL_PATH}/jsoncpp-1.9.5/

#检查是否已经创建。
if [ ! -f ${STAPLER_TARGET_PREFIX_PATH}/lib/libjsoncpp.so ] && [ ! -f ${STAPLER_TARGET_PREFIX_PATH}/lib64/libjsoncpp.so ] ;then
{
    #临时目录。
    BUILD_TMP_PATH=${STAPLER_BUILD_PATH}/jsoncpp/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/

    #执行配置。
    ${STAPLER_NATIVE_PREFIX_PATH}/bin/cmake ${JSONCPP_SRC_PATH} \
        -DCMAKE_PREFIX_PATH=${STAPLER_TARGET_PREFIX_PATH}/ \
        -DCMAKE_INSTALL_PREFIX=${STAPLER_TARGET_PREFIX_PATH}/ \
        -DCMAKE_CXX_COMPILER=${STAPLER_TARGET_COMPILER_CXX} \
        -DCMAKE_STRIP=${STAPLER_TARGET_COMPILER_PREFIX}strip \
        -D3RDPART_LIBS_DIR=${STAPLER_TARGET_PREFIX_PATH}/:${STAPLER_TARGET_COMPILER_SYSROOT} \
        -DCMAKE_FIND_ROOT_PATH=${STAPLER_TARGET_PREFIX_PATH}/ \
        -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
        -DCMAKE_C_FLAGS=-O3 \
        -DCMAKE_CXX_FLAGS=-O3 \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_STANDARD=11 \
        -DJSONCPP_WITH_TESTS=OFF \
        -DJSONCPP_WITH_POST_BUILD_UNITTEST=OFF
    exit_if_error $? "jsoncpp配置错误。" 1

    #编译。
    make -s -j4
    exit_if_error $? "jsoncpp编译错误。" 1

    #安装。
    make install 
    exit_if_error $? "jsoncpp安装错误。" 1


    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi