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
${TARGET_COMPILER_CXX} -E -dM -std=c++17 - </dev/null >/dev/null 2>&1
CHK=$?

#
if [ ${CHK} -ne 0 ];then
    exit_if_error 1 "OpenVDB需要c++17或更新的编译器。" 0
fi

#
MAJOR_VER=$(${TARGET_COMPILER_CXX} -dM -E - < /dev/null |grep __GNUC__ | cut -d ' ' -f 3)
MINOR_VER=$(${TARGET_COMPILER_CXX} -dM -E - < /dev/null |grep __GNUC_MINOR__ | cut -d ' ' -f 3)
PATCH_VER=$(${TARGET_COMPILER_CXX} -dM -E - < /dev/null |grep __GNUC_PATCHLEVEL__ | cut -d ' ' -f 3)

#
NUM_VER=$(expr ${MAJOR_VER} \* 10000 + ${MINOR_VER} \* 100 + ${PATCH_VER})

#
if [ ${NUM_VER} -lt 70000 ];then
    exit_if_error 1 "OpenVDB需要gcc(7.0.0)或更新的编译器。" 0
fi


#
OPENVDB_SRC_PATH=${SHELL_PATH}/openvdb-11.0.0/

#检查是否已经创建。
if [ ! -f ${TARGET_PREFIX_PATH}/lib/libopenvdb.so ];then
{
    #临时目录。
    BUILD_TMP_PATH=${BUILD_PATH}/openvdb/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/
    #复制源码到临时目录。
    cp -rf ${OPENVDB_SRC_PATH}/* ${BUILD_TMP_PATH}/
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/build

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/build
      
    #执行配置。
    if [ "${TARGET_PLATFORM}" == "aarch64" ];then
        TARGET_MAKEFILE_CONF="-DCROSS_COMPILE_ARM=1  -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=aarch64"
    elif [ "${TARGET_PLATFORM}" == "arm" ];then
        TARGET_MAKEFILE_CONF="-DCROSS_COMPILE_ARM=1 -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=armv7"
    else
        TARGET_MAKEFILE_CONF="-DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=x86_64"
    fi

    #        

    #执行配置。
    ${NATIVE_PREFIX_PATH}/bin/cmake ${BUILD_TMP_PATH}/ \
        ${TARGET_MAKEFILE_CONF} \
        -G "Unix Makefiles" \
        -DCMAKE_PREFIX_PATH=${TARGET_PREFIX_PATH}/ \
        -DCMAKE_INSTALL_PREFIX=${TARGET_PREFIX_PATH}/ \
        -DCMAKE_C_COMPILER=${TARGET_COMPILER_C} \
        -DCMAKE_CXX_COMPILER=${TARGET_COMPILER_CXX} \
        -DCMAKE_LINKER=${TARGET_COMPILER_LD} \
        -DCMAKE_AR=${TARGET_COMPILER_AR} \
        -DCMAKE_FIND_ROOT_PATH=${TARGET_PREFIX_PATH}/ \
        -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
        -DCMAKE_C_FLAGS="-O3 -fPIC" \
        -DCMAKE_CXX_FLAGS="-O3 -fPIC" \
        -DCMAKE_EXE_LINKER_FLAGS="-L${TARGET_PREFIX_PATH}/lib -llz4" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_STANDARD=17 \
        -DDISABLE_DEPENDENCY_VERSION_CHECKS=ON 
    exit_if_error $? "OpenVDB配置错误。" 1

    #编译。
    make -s -j4
    exit_if_error $? "OpenVDB编译错误。" 1

     #安装。
    make install 
    exit_if_error $? "OpenVDB安装错误。" 1


    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi
