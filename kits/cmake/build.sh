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
CMAKE_SRC_PATH=${SHELL_PATH}/cmake-3.26.4/

#检查是否已经创建。
if [ ! -f ${STAPLER_NATIVE_PREFIX_PATH}/bin/cmake ];then
{
    #临时目录。
    BUILD_TMP_PATH=${STAPLER_BUILD_PATH}/cmake/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/
    #复制源码到临时目录(包括隐藏文件)。
    cp -rf ${CMAKE_SRC_PATH}/. ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/

    #给配置工具增加执行权限。
    chmod +0500 bootstrap
    chmod +0500 configure

    #执行配置。
    ./bootstrap --prefix=${STAPLER_NATIVE_PREFIX_PATH}/ --parallel=6 CC=${STAPLER_NATIVE_COMPILER_C} CXX=${STAPLER_NATIVE_COMPILER_CXX} --no-qt-gui
    exit_if_error $? "cmake配置错误。" 1

    #编译。
    make -s -j4
    exit_if_error $? "cmake编译错误。" 1

    #安装。
    make install 
    exit_if_error $? "cmake安装错误。" 1


    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi