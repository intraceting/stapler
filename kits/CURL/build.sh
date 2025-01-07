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
CURL_SRC_PATH=${SHELL_PATH}/curl-curl-8_2_0/

#检查是否已经创建。
if [ ! -f ${TARGET_PERFIX_PATH}/lib/libcurl.so ];then
{
    #临时目录。
    BUILD_TMP_PATH=${BUILD_PATH}/curl/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/

    #执行配置。
    ${NATIVE_PERFIX_PATH}/bin/cmake ${CURL_SRC_PATH} \
        -DCMAKE_PREFIX_PATH=${TARGET_PERFIX_PATH}/ \
        -DCMAKE_INSTALL_PREFIX=${TARGET_PERFIX_PATH}/ \
        -DCMAKE_C_COMPILER=${TARGET_COMPILER_C} \
        -DCMAKE_CXX_COMPILER=${TARGET_COMPILER_CXX} \
        -DCMAKE_LINKER=${TARGET_COMPILER_LD} \
        -DCMAKE_AR=${TARGET_COMPILER_AR} \
        -DCMAKE_FIND_ROOT_PATH=${TARGET_PERFIX_PATH}/ \
        -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
        -DCMAKE_EXE_LINKER_FLAGS="-Wl,-rpath-link,${TARGET_PERFIX_PATH}/lib" \
        -DCMAKE_C_FLAGS=-O3 \
        -DCMAKE_CXX_FLAGS=-O3 \
        -DCMAKE_BUILD_TYPE=Release \
        -DTOOLCHAIN_DIR=${TARGET_COMPILER_HOME} \
        -D3RDPART_LIBS_DIR=${TARGET_PERFIX_PATH}/:${TARGET_COMPILER_HOME}
    exit_if_error $? "curl配置错误。" 1

    #编译。
    make -s -j4
    exit_if_error $? "curl编译错误。" 1

    # #安装。
    make install 
    exit_if_error $? "curl安装错误。" 1


    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi