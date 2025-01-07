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

#执行配置。
if [ "${TARGET_PLATFORM}" == "aarch64" ];then
    exit_if_error 1 "nginx不支持此平台。" 0
elif [ "${TARGET_PLATFORM}" == "arm" ];then
    exit_if_error 1 "nginx不支持此平台。" 0
else
    exit_if_error 1 "nginx不支持此平台。" 0
fi

#
NGINX_SRC_PATH=${SHELL_PATH}/nginx-1.25.1/
RTMP_SRC_PATH=${SHELL_PATH}/nginx-rtmp-module-1.2.2/
PCRE_SRC_PATH=${SHELL_PATH}/../pcre/pcre-8.45/
OPENSSL_SRC_PATH=${SHELL_PATH}/../openssl/openssl-1.1.1s/
ZLIB_SRC_PATH=${SHELL_PATH}/../zlib/zlib-1.2.13/

#检查是否已经创建。
if [ ! -f ${TARGET_PERFIX_PATH}/sbin/nginx ];then
{
    #临时目录。
    BUILD_TMP_PATH=${BUILD_PATH}/nginx/
    BUILD_RTMP_TMP_PATH=${BUILD_PATH}/nginx-rtmp-module/
    BUILD_PCRE_TMP_PATH=${BUILD_PATH}/pcre/
    BUILD_OPENSSL_TMP_PATH=${BUILD_PATH}/openssl/
    BUILD_ZLIB_TMP_PATH=${BUILD_PATH}/zlib/
    #删除过时的配置。
    rm -rf ${BUILD_TMP_PATH}
    rm -rf ${BUILD_RTMP_TMP_PATH}
    rm -rf ${BUILD_PCRE_TMP_PATH}
    rm -rf ${BUILD_OPENSSL_TMP_PATH}
    rm -rf ${BUILD_ZLIB_TMP_PATH}
    #生成临时目录。
    mkdir -p ${BUILD_TMP_PATH}/
    mkdir -p ${BUILD_RTMP_TMP_PATH}/
    mkdir -p ${BUILD_PCRE_TMP_PATH}/
    mkdir -p ${BUILD_OPENSSL_TMP_PATH}/
    mkdir -p ${BUILD_ZLIB_TMP_PATH}/
    #复制源码到临时目录。
    cp -rf ${NGINX_SRC_PATH}/* ${BUILD_TMP_PATH}/
    cp -rf ${RTMP_SRC_PATH}/* ${BUILD_RTMP_TMP_PATH}/
    cp -rf ${PCRE_SRC_PATH}/* ${BUILD_PCRE_TMP_PATH}/
    cp -rf ${OPENSSL_SRC_PATH}/* ${BUILD_OPENSSL_TMP_PATH}/
    cp -rf ${ZLIB_SRC_PATH}/* ${BUILD_ZLIB_TMP_PATH}/

    #进入临时目录。
    cd ${BUILD_TMP_PATH}/

    #给配置工具增加执行权限。
    chmod +0500 configure

    #    --with-pcre=${BUILD_PCRE_TMP_PATH}/ \
     #   --with-openssl=${BUILD_OPENSSL_TMP_PATH}/ \
     #   --with-zlib=${BUILD_ZLIB_TMP_PATH}/ \
    #执行配置。
    ./configure \
        --prefix=${TARGET_PERFIX_PATH}/ \
        --user=root --group=root \
        --sbin-path=/usr/local/nginx/sbin/nginx \
        --conf-path=/usr/local/nginx/conf/nginx.conf \
        --pid-path=/usr/local/nginx/logs/nginx.pid \
        --error-log-path=/usr/local/nginx/logs/error.log \
        --http-log-path=/usr/local/nginx/logs/access.log \
        --crossbuild=${TARGET_MACHINE} \
        --with-cc=${TARGET_COMPILER_C} \
        --with-cpp=${TARGET_COMPILER_CXX} \
        --with-cc-opt='-D_FILE_OFFSET_BITS=64 -D_LARGE_FILE' \
        --with-ld-opt='-D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE' \
        --add-module=${BUILD_RTMP_TMP_PATH}/ \
        --with-http_ssl_module \
        --with-http_v2_module  \
        --with-http_sub_module \
        --with-http_flv_module \
        --with-http_mp4_module \
        --with-http_auth_request_module \
        --with-http_random_index_module \
        --with-http_stub_status_module
    exit_if_error $? "nginx配置错误。" 1

    #编译。
    make
    exit_if_error $? "nginx编译错误。" 1

    #安装。
    make install 
    exit_if_error $? "nginx安装错误。" 1

    #恢复工作目录。
    cd ${SHELL_PATH}
}
fi