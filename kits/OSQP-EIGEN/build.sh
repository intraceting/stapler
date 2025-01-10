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
OSQP_EIGEN_SRC_PATH=${SHELL_PATH}/osqp-eigen-20240116/

#检查是否已经创建。
if [ ! -f ${TARGET_PREFIX_PATH}/lib/libOsqpEigen.so ];then
{
    #临时目录。
    BUILD_TMP_PATH=${BUILD_PATH}/libOsqpEigen/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/

    #指定交叉编译环境的目录
    #set(CMAKE_FIND_ROOT_PATH ${TARGET_COMPILER_SYSROOT})
    #从来不在指定目录(交叉编译)下查找工具程序。(编译时利用的是宿主的工具)
    #set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
    #只在指定目录(交叉编译)下查找库文件
    #set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
    #只在指定目录(交叉编译)下查找头文件
    #set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
    #只在指定的目录(交叉编译)下查找依赖包
    #set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

    #执行配置。
    ${NATIVE_PREFIX_PATH}/bin/cmake ${OSQP_EIGEN_SRC_PATH} \
        -DCMAKE_PREFIX_PATH=${TARGET_PREFIX_PATH}/ \
        -DCMAKE_INSTALL_PREFIX=${TARGET_PREFIX_PATH}/ \
        -DCMAKE_C_COMPILER=${TARGET_COMPILER_C} \
        -DCMAKE_CXX_COMPILER=${TARGET_COMPILER_CXX} \
        -DCMAKE_FIND_ROOT_PATH=${TARGET_PREFIX_PATH}/ \
        -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
        -DCMAKE_C_FLAGS="-O3" \
        -DCMAKE_CXX_FLAGS="-O3" \
        -DCMAKE_BUILD_TYPE=Release 
    exit_if_error $? "libOsqpEigen配置错误。" 1


    #编译。
    make -s -j4
    exit_if_error $? "libOsqpEigen编译错误。" 1

    #安装。
    make install 
    exit_if_error $? "libOsqpEigen安装错误。" 1


    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi