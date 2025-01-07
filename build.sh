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
NATIVE_COMPILER_HOME=/usr/
NATIVE_COMPILER_PREFIX=${NATIVE_COMPILER_HOME}/bin/
NATIVE_COMPILER_C=
NATIVE_COMPILER_CXX=
NATIVE_COMPILER_AR=
NATIVE_COMPILER_LD=
NATIVE_COMPILER_RANLIB=
NATIVE_COMPILER_READELF=

#
TARGET_COMPILER_HOME=
TARGET_COMPILER_PREFIX=
TARGET_COMPILER_C=
TARGET_COMPILER_CXX=
TARGET_COMPILER_AR=
TARGET_COMPILER_LD=
TARGET_COMPILER_RANLIB=
TARGET_COMPILER_READELF=

#
BUILD_PATH=${SHELL_PATH}/build/
ROOTFS_PATH=${SHELL_PATH}/rootfs/

#
PrintUsage()
{
cat << EOF
usage: [ OPTIONS ]
    -h
    打印此文档。

    -e < name=value >
     自定义环境变量。
     
     NATIVE_COMPILER_HOME=${NATIVE_COMPILER_HOME}
     NATIVE_COMPILER_PREFIX=${NATIVE_COMPILER_PREFIX}
     NATIVE_COMPILER_C=\${NATIVE_COMPILER_PREFIX}gcc
     NATIVE_COMPILER_CXX=\${NATIVE_COMPILER_PREFIX}g++
     NATIVE_COMPILER_AR=\${NATIVE_COMPILER_PREFIX}ar
     NATIVE_COMPILER_LD=\${NATIVE_COMPILER_PREFIX}ld
     NATIVE_COMPILER_RANLIB=\${NATIVE_COMPILER_PREFIX}ranlib
     NATIVE_COMPILER_READELF=\${NATIVE_COMPILER_PREFIX}readelf

     TARGET_COMPILER_HOME=\${NATIVE_COMPILER_HOME}
     TARGET_COMPILER_PREFIX=\${NATIVE_COMPILER_PREFIX}
     TARGET_COMPILER_C=\${NATIVE_COMPILER_PREFIX}gcc
     TARGET_COMPILER_CXX=\${NATIVE_COMPILER_PREFIX}g++
     TARGET_COMPILER_AR=\${NATIVE_COMPILER_PREFIX}ar
     TARGET_COMPILER_AR=\${NATIVE_COMPILER_PREFIX}ld
     TARGET_COMPILER_RANLIB=\${NATIVE_COMPILER_PREFIX}ranlib
     TARGET_COMPILER_READELF=\${NATIVE_COMPILER_PREFIX}readelf


    -b < path >
     构建目录。默认：${BUILD_PATH}

    -p < path >
     ROOTFS目录。默认：${ROOTFS_PATH}

EOF
}

#
while getopts "he:b:" ARGKEY 
do
    case $ARGKEY in
    \?)
        PrintUsage
        exit 22
    ;;
    h)
        PrintUsage
        exit 0
    ;;
    e)
        # 使用正则表达式检查参数是否为 "key=value" 或 "key=" 的格式.
        if [[ "$OPTARG" =~ ^[a-zA-Z_][a-zA-Z0-9_]*=.*$ ]]; then
            eval ${OPTARG}
        else 
            echo "'-e ${OPTARG}' will be ignored, the parameter of '- e' only supports the format of 'key=value' or 'key=' ."
        fi 
    ;;
    b)
        BUILD_PATH="${OPTARG}"
    ;;
    esac
done

#修复默认值。
if [ "${NATIVE_COMPILER_HOME}" == "" ];then
NATIVE_COMPILER_HOME=/usr/
fi
#修复默认值。
if [ "${NATIVE_COMPILER_PREFIX}" == "" ];then
NATIVE_COMPILER_PREFIX=${NATIVE_COMPILER_HOME}/bin/
fi
#修复默认值。
if [ "${NATIVE_COMPILER_C}" == "" ];then
NATIVE_COMPILER_C=${NATIVE_COMPILER_PREFIX}gcc
fi
#修复默认值。
if [ "${NATIVE_COMPILER_CXX}" == "" ];then
NATIVE_COMPILER_CXX=${NATIVE_COMPILER_PREFIX}g++
fi
#修复默认值。
if [ "${NATIVE_COMPILER_AR}" == "" ];then
NATIVE_COMPILER_AR=${NATIVE_COMPILER_PREFIX}ar
fi
#修复默认值。
if [ "${NATIVE_COMPILER_LD}" == "" ];then
NATIVE_COMPILER_LD=${NATIVE_COMPILER_PREFIX}ld
fi
#修复默认值。
if [ "${NATIVE_COMPILER_RANLIB}" == "" ];then
NATIVE_COMPILER_RANLIB=${NATIVE_COMPILER_PREFIX}ranlib
fi
#修复默认值。
if [ "${NATIVE_COMPILER_READELF}" == "" ];then
NATIVE_COMPILER_READELF=${NATIVE_COMPILER_PREFIX}readelf
fi

#检查参数。
if [ ! -d ${NATIVE_COMPILER_HOME} ];then
echo "\'${NATIVE_COMPILER_HOME}\'不存在."
exit 22
fi
#检查参数。
if [ ! -f ${NATIVE_COMPILER_C} ];then
echo "\'${NATIVE_COMPILER_C}\'不存在."
exit 22
fi
#检查参数。
if [ ! -f ${NATIVE_COMPILER_CXX} ];then
echo "\'${NATIVE_COMPILER_CXX}\'不存在."
exit 22
fi
#检查参数。
if [ ! -f ${NATIVE_COMPILER_AR} ];then
echo "\'${NATIVE_COMPILER_AR}\'不存在."
exit 22
fi
#检查参数。
if [ ! -f ${NATIVE_COMPILER_LD} ];then
echo "\'${NATIVE_COMPILER_LD}\'不存在."
exit 22
fi
#检查参数。
if [ ! -f ${NATIVE_COMPILER_RANLIB} ];then
echo "\'${NATIVE_COMPILER_RANLIB}\'不存在."
exit 22
fi
#检查参数。
if [ ! -f ${NATIVE_COMPILER_READELF} ];then
echo "\'${NATIVE_COMPILER_READELF}\'不存在."
exit 22
fi

#
export NATIVE_COMPILER_HOME
export NATIVE_COMPILER_PREFIX
export NATIVE_COMPILER_C
export NATIVE_COMPILER_CXX
export NATIVE_COMPILER_AR
export NATIVE_COMPILER_LD
export NATIVE_COMPILER_RANLIB
export NATIVE_COMPILER_READELF



#修复默认值。
if [ "${TARGET_COMPILER_HOME}" == "" ];then
TARGET_COMPILER_HOME=${NATIVE_COMPILER_HOME}
fi
#修复默认值。
if [ "${TARGET_COMPILER_PREFIX}" == "" ];then
TARGET_COMPILER_PREFIX=${NATIVE_COMPILER_PREFIX}
fi
#修复默认值。
if [ "${TARGET_COMPILER_C}" == "" ];then
TARGET_COMPILER_C=${TARGET_COMPILER_PREFIX}gcc
fi
#修复默认值。
if [ "${TARGET_COMPILER_CXX}" == "" ];then
TARGET_COMPILER_CXX=${TARGET_COMPILER_PREFIX}g++
fi
#修复默认值。
if [ "${TARGET_COMPILER_AR}" == "" ];then
TARGET_COMPILER_AR=${TARGET_COMPILER_PREFIX}ar
fi
#修复默认值。
if [ "${TARGET_COMPILER_LD}" == "" ];then
TARGET_COMPILER_LD=${TARGET_COMPILER_PREFIX}ld
fi
#修复默认值。
if [ "${TARGET_COMPILER_RANLIB}" == "" ];then
TARGET_COMPILER_RANLIB=${TARGET_COMPILER_PREFIX}ranlib
fi
#修复默认值。
if [ "${TARGET_COMPILER_READELF}" == "" ];then
TARGET_COMPILER_READELF=${TARGET_COMPILER_PREFIX}readelf
fi

#检查参数。
if [ ! -d ${TARGET_COMPILER_HOME} ];then
echo "\'${TARGET_COMPILER_HOME}\'不存在."
exit 22
fi
#检查参数。
if [ ! -f ${TARGET_COMPILER_C} ];then
echo "\'${TARGET_COMPILER_C}\'不存在."
exit 22
fi
#检查参数。
if [ ! -f ${NATIVE_COMPILER_CXX} ];then
echo "\'${NATIVE_COMPILER_CXX}\'不存在."
exit 22
fi
#检查参数。
if [ ! -f ${TARGET_COMPILER_AR} ];then
echo "\'${TARGET_COMPILER_AR}\'不存在."
exit 22
fi
#检查参数。
if [ ! -f ${TARGET_COMPILER_LD} ];then
echo "\'${TARGET_COMPILER_LD}\'不存在."
exit 22
fi
#检查参数。
if [ ! -f ${TARGET_COMPILER_RANLIB} ];then
echo "\'${TARGET_COMPILER_RANLIB}\'不存在."
exit 22
fi
#检查参数。
if [ ! -f ${TARGET_COMPILER_READELF} ];then
echo "\'${TARGET_COMPILER_READELF}\'不存在."
exit 22
fi

#
export TARGET_COMPILER_HOME
export TARGET_COMPILER_PREFIX
export TARGET_COMPILER_C
export TARGET_COMPILER_CXX
export TARGET_COMPILER_AR
export TARGET_COMPILER_LD
export TARGET_COMPILER_RANLIB
export TARGET_COMPILER_READELF

#修复默认值。
if [ "${BUILD_PATH}" == "" ];then
BUILD_PATH=${SHELL_PATH}/build/
fi

#修复默认值。
export BUILD_PATH

#修复默认值。
if [ "${ROOTFS_PATH}" == "" ];then
ROOTFS_PATH=${SHELL_PATH}/rootfs/
fi


#编译过程中临时文件目录。
export TMPDIR=${BUILD_PATH}/

#
export NATIVE_MACHINE=$(${NATIVE_COMPILER_C} -dumpmachine 2>/dev/null)
export TARGET_MACHINE=$(${TARGET_COMPILER_C} -dumpmachine 2>/dev/null)

#
export NATIVE_PLATFORM=$(echo ${NATIVE_MACHINE} | cut -d - -f 1)
export TARGET_PLATFORM=$(echo ${TARGET_MACHINE} | cut -d - -f 1)

#
export NATIVE_COMPILER_VERSION=$(${NATIVE_COMPILER_C} -dumpversion 2>/dev/null)
export TARGET_COMPILER_VERSION=$(${TARGET_COMPILER_C} -dumpversion 2>/dev/null)

#查找libc.so文件路径。
TARGET_GLIBC_SO_FILE=$(find ${TARGET_COMPILER_HOME} -name libc.so.6 |grep ${TARGET_MACHINE} |head -n 1)

#提取glibc最大版本。
NATIVE_GLIBC_MAX_VER=$(ldd --version |head -n 1 |rev |cut -d ' ' -f 1 |rev)
TARGET_GLIBC_MAX_VER=$(${TARGET_COMPILER_READELF} -V ${TARGET_GLIBC_SO_FILE} | grep -o 'GLIBC_[0-9]\+\.[0-9]\+' | sort -u -V -r |head -n 1 |cut -d '_' -f 2)

#
if [ "${NATIVE_GLIBC_MAX_VER}" == "" ];then
echo "无法获取本机平台的glibc版本."
exit 1
fi

#
if [ "${TARGET_GLIBC_MAX_VER}" == "" ];then
echo "无法获取目标平台的glibc版本."
exit 1
fi


#
export NATIVE_PERFIX_PATH=${ROOTFS_PATH}/${NATIVE_MACHINE}/glibc-${NATIVE_GLIBC_MAX_VER}/
export TARGET_PERFIX_PATH=${ROOTFS_PATH}/${TARGET_MACHINE}/glibc-${TARGET_GLIBC_MAX_VER}/


#限制目标平台.pc文件搜索路径范围。
export PKG_CONFIG_LIBDIR=${TARGET_PERFIX_PATH}/lib/pkgconfig
#export PKG_CONFIG_PATH=${TARGET_PERFIX_PATH}/lib/pkgconfig:${PKG_CONFIG_PATH}

#如果是本地编译，添加编译输出目录(lib)为动态库的搜索路径，因为有的工具包在编译和安装的过程中会进行本地验证。
if [ "${NATIVE_PLATFORM}" == "${TARGET_PLATFORM}" ];then
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${TARGET_PERFIX_PATH}/lib
fi


#生成不存在的路径。
mkdir -p ${NATIVE_PERFIX_PATH}/
mkdir -p ${TARGET_PERFIX_PATH}/
mkdir -p ${BUILD_PATH}/

#指定交叉编译环境的目录
#set(CMAKE_FIND_ROOT_PATH ${TARGET_COMPILER_HOME})
#从来不在指定目录(交叉编译)下查找工具程序。(编译时利用的是宿主的工具)
#set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
#只在指定目录(交叉编译)下查找库文件
#set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
#只在指定目录(交叉编译)下查找头文件
#set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
#只在指定的目录(交叉编译)下查找依赖包
#set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/cmake/build.sh
${SHELL_PATH}/kits/cmake/build.sh
exit_if_error $? "终止。" 1

echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/openblas/build.sh
${SHELL_PATH}/kits/openblas/build.sh
exit_if_error $? "终止。" 1

echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/eigen/build.sh
${SHELL_PATH}/kits/eigen/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"
#
chmod +500 ${SHELL_PATH}/kits/openssl/build.sh
${SHELL_PATH}/kits/openssl/build.sh
exit_if_error $? "终止。" 1

echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


# #
# chmod +500 ${SHELL_PATH}/kits/nasm/build.sh
# ${SHELL_PATH}/kits/nasm/build.sh
# exit_if_error $? "终止。" 1

# echo "----------------------------------------------------------------------------"
# echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/yasm/build.sh
${SHELL_PATH}/kits/yasm/build.sh
exit_if_error $? "终止。" 1

echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/x264/build.sh
${SHELL_PATH}/kits/x264/build.sh
exit_if_error $? "终止。" 1

echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/x265/build.sh
${SHELL_PATH}/kits/x265/build.sh
exit_if_error $? "终止。" 1

echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/ffmpeg/build.sh
${SHELL_PATH}/kits/ffmpeg/build.sh
exit_if_error $? "终止。" 1

echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/jsoncpp/build.sh
${SHELL_PATH}/kits/jsoncpp/build.sh
exit_if_error $? "终止。" 1

echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/faiss/build.sh
${SHELL_PATH}/kits/faiss/build.sh
exit_if_error $? "终止。" 1

echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/freetype/build.sh
${SHELL_PATH}/kits/freetype/build.sh
exit_if_error $? "终止。" 1

echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/zlib/build.sh
${SHELL_PATH}/kits/zlib/build.sh
exit_if_error $? "终止。" 1

echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/pixman/build.sh
${SHELL_PATH}/kits/pixman/build.sh
exit_if_error $? "终止。" 1

echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/cairo/build.sh
${SHELL_PATH}/kits/cairo/build.sh
exit_if_error $? "终止。" 1

echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/harfbuzz/build.sh
${SHELL_PATH}/kits/harfbuzz/build.sh
exit_if_error $? "终止。" 1

echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/opencv/build.sh
${SHELL_PATH}/kits/opencv/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/sqlite/build.sh
${SHELL_PATH}/kits/sqlite/build.sh
exit_if_error $? "终止。" 1

echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/libhiredis/build.sh
${SHELL_PATH}/kits/libhiredis/build.sh
exit_if_error $? "终止。" 1

echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/librdkafka/build.sh
${SHELL_PATH}/kits/librdkafka/build.sh
exit_if_error $? "终止。" 1

echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/libyuv/build.sh
${SHELL_PATH}/kits/libyuv/build.sh
exit_if_error $? "终止。" 1

echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/boost/build.sh
${SHELL_PATH}/kits/boost/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/libmosquitto/build.sh
${SHELL_PATH}/kits/libmosquitto/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/stb/build.sh
${SHELL_PATH}/kits/stb/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/cimg/build.sh
${SHELL_PATH}/kits/cimg/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/fastcgi/build.sh
${SHELL_PATH}/kits/fastcgi/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/libuuid/build.sh
${SHELL_PATH}/kits/libuuid/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/libev/build.sh
${SHELL_PATH}/kits/libev/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/c-ares/build.sh
${SHELL_PATH}/kits/c-ares/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/nghttp2/build.sh
${SHELL_PATH}/kits/nghttp2/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/mongoose/build.sh
${SHELL_PATH}/kits/mongoose/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"



#
chmod +500 ${SHELL_PATH}/kits/nlohmann/build.sh
${SHELL_PATH}/kits/nlohmann/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"



#
chmod +500 ${SHELL_PATH}/kits/cpp-httplib/build.sh
${SHELL_PATH}/kits/cpp-httplib/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"



#
chmod +500 ${SHELL_PATH}/kits/Bento4/build.sh
${SHELL_PATH}/kits/Bento4/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/live555/build.sh
${SHELL_PATH}/kits/live555/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/CURL/build.sh
${SHELL_PATH}/kits/CURL/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/octomap/build.sh
${SHELL_PATH}/kits/octomap/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/pcre/build.sh
${SHELL_PATH}/kits/pcre/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/PCRE2/build.sh
${SHELL_PATH}/kits/PCRE2/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/lighttpd/build.sh
${SHELL_PATH}/kits/lighttpd/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"



#
chmod +500 ${SHELL_PATH}/kits/camport3/build.sh
${SHELL_PATH}/kits/camport3/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/NGINX/build.sh
${SHELL_PATH}/kits/NGINX/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/srs/build.sh
${SHELL_PATH}/kits/srs/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/lz4/build.sh
${SHELL_PATH}/kits/lz4/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/flann/build.sh
${SHELL_PATH}/kits/flann/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/PCL/build.sh
${SHELL_PATH}/kits/PCL/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/python/build.sh
${SHELL_PATH}/kits/python/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/ZLMediaKit/build.sh
${SHELL_PATH}/kits/ZLMediaKit/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/BYACC/build.sh
${SHELL_PATH}/kits/BYACC/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/SOAP/build.sh
${SHELL_PATH}/kits/SOAP/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/XSIMD/build.sh
${SHELL_PATH}/kits/XSIMD/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/GTL/build.sh
${SHELL_PATH}/kits/GTL/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/GLOG/build.sh
${SHELL_PATH}/kits/GLOG/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/GFLAGS/build.sh
${SHELL_PATH}/kits/GFLAGS/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/NPY/build.sh
${SHELL_PATH}/kits/NPY/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/ISC-Projects/build.sh
${SHELL_PATH}/kits/ISC-Projects/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/OSQP/build.sh
${SHELL_PATH}/kits/OSQP/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/OSQP-EIGEN/build.sh
${SHELL_PATH}/kits/OSQP-EIGEN/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/libxml2/build.sh
${SHELL_PATH}/kits/libxml2/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/libxslt/build.sh
${SHELL_PATH}/kits/libxslt/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/YAML-CPP/build.sh
${SHELL_PATH}/kits/YAML-CPP/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/GDB/build.sh
${SHELL_PATH}/kits/GDB/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/OPENSSH/build.sh
${SHELL_PATH}/kits/OPENSSH/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/TBB/build.sh
${SHELL_PATH}/kits/TBB/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/BLOSC/build.sh
${SHELL_PATH}/kits/BLOSC/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"


#
chmod +500 ${SHELL_PATH}/kits/OpenVDB/build.sh
${SHELL_PATH}/kits/OpenVDB/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"
