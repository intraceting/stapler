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
CIMG_SRC_PATH=${SHELL_PATH}/CImg-v.3.2.4/

#检查是否已经创建。
if [ ! -f ${TARGET_PERFIX_PATH}/include/cimg/CImg.h ];then
{
    #创建安装目录。
    mkdir -p ${TARGET_PERFIX_PATH}/include/cimg/
    #不需要编译，直接复制源码到安装目录。
    cp -rf ${CIMG_SRC_PATH}/CImg.h ${TARGET_PERFIX_PATH}/include/cimg/
}
fi