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
PCL_SRC_PATH=${SHELL_PATH}/pcl-pcl-1.12.1/

#检查是否已经创建。
if [ ! -f ${STAPLER_TARGET_PREFIX_PATH}/lib/libpcl_common.so ];then
{
    #临时目录。
    BUILD_TMP_PATH=${STAPLER_BUILD_PATH}/pcl/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/
      
    #执行配置。
    if [ "${STAPLER_TARGET_PLATFORM}" == "aarch64" ];then
        TARGET_MAKEFILE_CONF="-DCROSS_COMPILE_ARM=1  -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=aarch64"
    elif [ "${STAPLER_TARGET_PLATFORM}" == "arm" ];then
        TARGET_MAKEFILE_CONF="-DCROSS_COMPILE_ARM=1 -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=armv7"
    else
        TARGET_MAKEFILE_CONF="-DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=x86_64"
    fi

    #        

    #执行配置。
    ${STAPLER_NATIVE_PREFIX_PATH}/bin/cmake ${PCL_SRC_PATH}/\
        ${TARGET_MAKEFILE_CONF} \
        -G "Unix Makefiles" \
        -DCMAKE_PREFIX_PATH=${STAPLER_TARGET_PREFIX_PATH}/ \
        -DCMAKE_INSTALL_PREFIX=${STAPLER_TARGET_PREFIX_PATH}/ \
        -DCMAKE_C_COMPILER=${STAPLER_TARGET_COMPILER_C} \
        -DCMAKE_CXX_COMPILER=${STAPLER_TARGET_COMPILER_CXX} \
        -DCMAKE_LINKER=${STAPLER_TARGET_COMPILER_LD} \
        -DCMAKE_AR=${STAPLER_TARGET_COMPILER_AR} \
        -DCMAKE_FIND_ROOT_PATH=${STAPLER_TARGET_PREFIX_PATH}/ \
        -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
        -DCMAKE_C_FLAGS="-O3 -fPIC -DBOOST_BIND_GLOBAL_PLACEHOLDERS -DEIGEN_DONT_ALIGN_STATICALLY" \
        -DCMAKE_CXX_FLAGS="-O3 -fPIC -DBOOST_BIND_GLOBAL_PLACEHOLDERS -DEIGEN_DONT_ALIGN_STATICALLY" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_STANDARD=11 \
        -DWITH_LIBUSB=FASLE \
        -DWITH_PNG=FALSE \
        -DWITH_QHULL=FALSE \
        -DWITH_CUDA=FALSE \
        -DWITH_QT=FALSE \
        -DWITH_VTK=FALSE \
        -DWITH_PCAP=FALSE \
        -DWITH_OPENGL=FALSE
    exit_if_error $? "PCL配置错误。" 1

    #编译。
    make -s -j4
    exit_if_error $? "PCL编译错误。" 1

     #安装。
    make install 
    exit_if_error $? "PCL安装错误。" 1


    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi
