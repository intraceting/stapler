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
LIVE555_SRC_PATH=${SHELL_PATH}/live_2023-06-20/

#检查是否已经创建。
if [ ! -f ${STAPLER_TARGET_PREFIX_PATH}/lib/libliveMedia.a ];then
{
    #临时目录。
    BUILD_TMP_PATH=${STAPLER_BUILD_PATH}/live/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/
    #复制源码到临时目录。
    cp -rf ${LIVE555_SRC_PATH}/* ${BUILD_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/


    #创建个性化配置文件
cat > config.private <<EOF
PREFIX = ${STAPLER_TARGET_PREFIX_PATH}/
LIBDIR = \$(PREFIX)/lib
#-DNO_STD_LIB 用于c++20以下。
COMPILE_OPTS = \$(INCLUDES) -I. -O3 -DSOCKLEN_T=socklen_t -D_LARGEFILE_SOURCE=1 -D_FILE_OFFSET_BITS=64 -std=c++11 -DNO_STD_LIB -Wno-deprecated -I${STAPLER_TARGET_PREFIX_PATH}/include/
C = c
C_COMPILER = ${STAPLER_TARGET_COMPILER_C}
C_FLAGS = \$(COMPILE_OPTS) \$(CPPFLAGS) \$(CFLAGS) 
CPP = cpp
CPLUSPLUS_COMPILER = ${STAPLER_TARGET_COMPILER_CXX}
CPLUSPLUS_FLAGS = \$(COMPILE_OPTS) -Wall -DBSD=1 \$(CPPFLAGS) \$(CXXFLAGS)
OBJ = o
LINK = ${STAPLER_TARGET_COMPILER_CXX} -o
LINK_OPTS =	-L. \$(LDFLAGS) -L${STAPLER_TARGET_PREFIX_PATH}/lib/
CONSOLE_LINK_OPTS =	\$(LINK_OPTS)
LIBRARY_LINK = ${STAPLER_TARGET_COMPILER_AR} cr 
LIBRARY_LINK_OPTS =	
LIB_SUFFIX = a
LIBS_FOR_CONSOLE_APPLICATION = -lssl -lcrypto
LIBS_FOR_GUI_APPLICATION =
EXE =
EOF

    #给配置工具增加执行权限。
    chmod +0500 genMakefiles
   
    #执行配置。
    ./genMakefiles private
    exit_if_error $? "live555配置错误。" 1

    #编译。
    make
    exit_if_error $? "live555编译错误。" 1

    #安装。
    make install 
    exit_if_error $? "live555安装错误。" 1

    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi