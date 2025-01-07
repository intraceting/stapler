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
BOOST_SRC_PATH=${SHELL_PATH}/boost_1_82_0/

#检查是否已经创建。
if [ ! -f ${TARGET_PERFIX_PATH}/lib/libboost_system.so ];then
{
    #临时目录。
    BUILD_TMP_PATH=${BUILD_PATH}/boost/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/
    #复制源码到临时目录。
    cp -rf ${BOOST_SRC_PATH}/* ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/

    #给配置工具增加执行权限。
    chmod +0500 ./bootstrap.sh

    #执行配置。
    ./bootstrap.sh \
        --without-libraries=python
    exit_if_error $? "boost配置错误。请重置本机的g++多版本配置，或重新安装本机g++编译器。" 1

    #
    export BOOST_BUILD_PATH=${BUILD_TMP_PATH}
    echo "using gcc : ${TARGET_COMPILER_VERSION} : ${TARGET_COMPILER_CXX} ;" > ${BOOST_BUILD_PATH}/user-config.jam

    #编译。
    ./b2 toolset=gcc
    exit_if_error $? "boost编译错误。" 1

    #安装。
    ./b2 --prefix=${TARGET_PERFIX_PATH}/ toolset=gcc install
    exit_if_error $? "boost安装错误。" 1



    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi
