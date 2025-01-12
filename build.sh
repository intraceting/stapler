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
which_status()
{
    which "${1}" 2>>/dev/null 1>>/dev/null
    echo $?
}

#
native_compiler_agent()
{
    if [ -f "${NATIVE_COMPILER_C}" ];then
        ${NATIVE_COMPILER_C} $*
    elif [ -f "${NATIVE_COMPILER_CXX}" ];then
        ${NATIVE_COMPILER_CXX} $*
    else 
        exit 127
    fi
}

#
target_compiler_agent()
{
    if [ -f "${TARGET_COMPILER_C}" ];then
        ${TARGET_COMPILER_C} $* 2>>/dev/null
    elif [ -f "${TARGET_COMPILER_CXX}" ];then
        ${TARGET_COMPILER_CXX} $* 2>>/dev/null
    else 
        exit 127
    fi
}

#
NATIVE_COMPILER_PREFIX=/usr/bin/
NATIVE_COMPILER_C=
NATIVE_COMPILER_CXX=
NATIVE_COMPILER_FORTRAN=
NATIVE_COMPILER_SYSROOT=
NATIVE_COMPILER_AR=
NATIVE_COMPILER_LD=
NATIVE_COMPILER_RANLIB=
NATIVE_COMPILER_READELF=

#
TARGET_COMPILER_PREFIX=/usr/bin/
TARGET_COMPILER_C=
TARGET_COMPILER_CXX=
TARGET_COMPILER_FORTRAN=
TARGET_COMPILER_SYSROOT=
TARGET_COMPILER_AR=
TARGET_COMPILER_LD=
TARGET_COMPILER_RANLIB=
TARGET_COMPILER_READELF=

#
BUILD_PATH=${SHELL_PATH}/build/
RELEASE_PATH=${SHELL_PATH}/release/

#
PrintUsage()
{
cat << EOF
usage: [ OPTIONS ]
    -h
    打印此文档。

    -e < name=value >
     自定义环境变量。
     
     NATIVE_COMPILER_PREFIX=${NATIVE_COMPILER_PREFIX}
     NATIVE_COMPILER_C=${NATIVE_COMPILER_C}
     NATIVE_COMPILER_CXX=${NATIVE_COMPILER_CXX}
     NATIVE_COMPILER_FORTRAN=${NATIVE_COMPILER_FORTRAN}
     NATIVE_COMPILER_SYSROOT=${NATIVE_COMPILER_SYSROOT}
     NATIVE_COMPILER_AR=${NATIVE_COMPILER_AR}
     NATIVE_COMPILER_LD=${NATIVE_COMPILER_LD}
     NATIVE_COMPILER_RANLIB=${NATIVE_COMPILER_RANLIB}
     NATIVE_COMPILER_READELF=${NATIVE_COMPILER_READELF}

     
     TARGET_COMPILER_PREFIX=${TARGET_COMPILER_PREFIX}
     TARGET_COMPILER_C=${TARGET_COMPILER_C}
     TARGET_COMPILER_CXX=${TARGET_COMPILER_CXX}
     TARGET_COMPILER_FORTRAN=${TARGET_COMPILER_FORTRAN}
     TARGET_COMPILER_SYSROOT=${TARGET_COMPILER_SYSROOT}
     TARGET_COMPILER_AR=${TARGET_COMPILER_AR}
     TARGET_COMPILER_LD=${TARGET_COMPILER_LD}
     TARGET_COMPILER_RANLIB=${TARGET_COMPILER_RANLIB}
     TARGET_COMPILER_READELF=${TARGET_COMPILER_READELF}

    -b < path >
     构建目录。默认：${BUILD_PATH}

    -r < path >
     发行目录。默认：${RELEASE_PATH}

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
    r)
        RELEASE_PATH="${OPTARG}"
    ;;
    esac
done

#################################################################################

#检查参数。
if [ "${NATIVE_COMPILER_PREFIX}" == "" ];then
echo "NATIVE_COMPILER_PREFIX=${NATIVE_COMPILER_PREFIX} 无效或不存在."
exit 22
fi

#修复默认值。
if [ "${NATIVE_COMPILER_C}" == "" ];then
NATIVE_COMPILER_C="${NATIVE_COMPILER_PREFIX}gcc"
fi
#修复默认值。
if [ "${NATIVE_COMPILER_CXX}" == "" ];then
NATIVE_COMPILER_CXX="${NATIVE_COMPILER_PREFIX}g++"
fi
#修复默认值。
if [ "${NATIVE_COMPILER_FORTRAN}" == "" ];then
NATIVE_COMPILER_FORTRAN="${NATIVE_COMPILER_PREFIX}gfortran"
fi
#修复默认值。
if [ "${NATIVE_COMPILER_SYSROOT}" == "" ];then
NATIVE_COMPILER_SYSROOT=$(native_compiler_agent "--print-sysroot")
fi
#修复默认值。
if [ "${NATIVE_COMPILER_AR}" == "" ];then
NATIVE_COMPILER_AR=$(native_compiler_agent "-print-prog-name=ar")
NATIVE_COMPILER_AR=$(which "${NATIVE_COMPILER_AR}")
fi
#修复默认值。
if [ "${NATIVE_COMPILER_LD}" == "" ];then
NATIVE_COMPILER_LD=$(native_compiler_agent "-print-prog-name=ld")
NATIVE_COMPILER_LD=$(which "${NATIVE_COMPILER_LD}")
fi
#修复默认值。
if [ "${NATIVE_COMPILER_RANLIB}" == "" ];then
NATIVE_COMPILER_RANLIB=$(native_compiler_agent "-print-prog-name=ranlib")
NATIVE_COMPILER_RANLIB=$(which "${NATIVE_COMPILER_RANLIB}")
fi
#修复默认值。
if [ "${NATIVE_COMPILER_READELF}" == "" ];then
NATIVE_COMPILER_READELF=$(native_compiler_agent "-print-prog-name=readelf")
NATIVE_COMPILER_READELF=$(which "${NATIVE_COMPILER_READELF}")
fi

#检查参数。
if [ ! -f "${NATIVE_COMPILER_C}" ];then
echo "NATIVE_COMPILER_C=${NATIVE_COMPILER_C} 无效或不存在."
exit 22
fi
#检查参数。
if [ ! -f "${NATIVE_COMPILER_CXX}" ];then
echo "NATIVE_COMPILER_CXX=${NATIVE_COMPILER_CXX} 无效或不存在."
exit 22
fi
#检查参数。
if [ ! -f "${NATIVE_COMPILER_FORTRAN}" ];then
echo "NATIVE_COMPILER_FORTRAN=${NATIVE_COMPILER_FORTRAN} 无效或不存在."
exit 22
fi
#检查参数。
if [ ! -f "${NATIVE_COMPILER_AR}" ];then
echo "NATIVE_COMPILER_AR=${NATIVE_COMPILER_AR} 无效或不存在."
exit 22
fi
#检查参数。
if [ ! -f "${NATIVE_COMPILER_LD}" ];then
echo "NATIVE_COMPILER_LD=${NATIVE_COMPILER_LD} 无效或不存在."
exit 22
fi
#检查参数。
if [ ! -f "${NATIVE_COMPILER_RANLIB}" ];then
echo "NATIVE_COMPILER_RANLIB=${NATIVE_COMPILER_RANLIB} 无效或不存在."
exit 22
fi
#检查参数。
if [ ! -f "${NATIVE_COMPILER_READELF}" ];then
echo "NATIVE_COMPILER_READELF=${NATIVE_COMPILER_READELF} 无效或不存在."
exit 22
fi


#################################################################################

#检查参数。
if [ "${TARGET_COMPILER_PREFIX}" == "" ];then
echo "TARGET_COMPILER_PREFIX=${TARGET_COMPILER_PREFIX} 无效或不存在."
exit 22
fi

#修复默认值。
if [ "${TARGET_COMPILER_C}" == "" ];then
TARGET_COMPILER_C="${TARGET_COMPILER_PREFIX}gcc"
fi
#修复默认值。
if [ "${TARGET_COMPILER_CXX}" == "" ];then
TARGET_COMPILER_CXX="${TARGET_COMPILER_PREFIX}g++"
fi
#修复默认值。
if [ "${TARGET_COMPILER_FORTRAN}" == "" ];then
TARGET_COMPILER_FORTRAN="${TARGET_COMPILER_PREFIX}gfortran"
fi
#修复默认值。
if [ "${TARGET_COMPILER_SYSROOT}" == "" ];then
TARGET_COMPILER_SYSROOT=$(target_compiler_agent "--print-sysroot")
fi
#修复默认值。
if [ "${TARGET_COMPILER_AR}" == "" ];then
TARGET_COMPILER_AR=$(target_compiler_agent "-print-prog-name=ar")
TARGET_COMPILER_AR=$(which "${TARGET_COMPILER_AR}")
fi
#修复默认值。
if [ "${TARGET_COMPILER_LD}" == "" ];then
TARGET_COMPILER_LD=$(target_compiler_agent "-print-prog-name=ld")
TARGET_COMPILER_LD=$(which "${TARGET_COMPILER_LD}")
fi
#修复默认值。
if [ "${TARGET_COMPILER_RANLIB}" == "" ];then
TARGET_COMPILER_RANLIB=$(target_compiler_agent "-print-prog-name=ranlib")
TARGET_COMPILER_RANLIB=$(which "${TARGET_COMPILER_RANLIB}")
fi
#修复默认值。
if [ "${TARGET_COMPILER_READELF}" == "" ];then
TARGET_COMPILER_READELF=$(target_compiler_agent "-print-prog-name=readelf")
TARGET_COMPILER_READELF=$(which "${TARGET_COMPILER_READELF}")
fi

#检查参数。
if [ ! -f "${TARGET_COMPILER_C}" ];then
echo "TARGET_COMPILER_C=${TARGET_COMPILER_C} 无效或不存在."
exit 22
fi
#检查参数。
if [ ! -f "${TARGET_COMPILER_CXX}" ];then
echo "TARGET_COMPILER_CXX=${TARGET_COMPILER_CXX} 无效或不存在."
exit 22
fi
#检查参数。
if [ ! -f "${TARGET_COMPILER_FORTRAN}" ];then
echo "TARGET_COMPILER_FORTRAN=${TARGET_COMPILER_FORTRAN} 无效或不存在."
exit 22
fi
#检查参数。
if [ ! -f "${TARGET_COMPILER_AR}" ];then
echo "TARGET_COMPILER_AR=${TARGET_COMPILER_AR} 无效或不存在."
exit 22
fi
#检查参数。
if [ ! -f "${TARGET_COMPILER_LD}" ];then
echo "TARGET_COMPILER_LD=${TARGET_COMPILER_LD} 无效或不存在."
exit 22
fi
#检查参数。
if [ ! -f "${TARGET_COMPILER_RANLIB}" ];then
echo "TARGET_COMPILER_RANLIB=${TARGET_COMPILER_RANLIB} 无效或不存在."
exit 22
fi
#检查参数。
if [ ! -f "${TARGET_COMPILER_READELF}" ];then
echo "TARGET_COMPILER_READELF=${TARGET_COMPILER_READELF} 无效或不存在."
exit 22
fi

#################################################################################

#修复默认值。
if [ "${BUILD_PATH}" == "" ];then
BUILD_PATH=${SHELL_PATH}/build/
fi

#编译过程中临时文件存放的目录。
TMPDIR=${BUILD_PATH}/


#修复默认值。
if [ "${RELEASE_PATH}" == "" ];then
RELEASE_PATH=${SHELL_PATH}/release/
fi

#################################################################################

#
NATIVE_MACHINE=$(${NATIVE_COMPILER_C} -dumpmachine 2>/dev/null)
TARGET_MACHINE=$(${TARGET_COMPILER_C} -dumpmachine 2>/dev/null)

#
NATIVE_PLATFORM=$(echo ${NATIVE_MACHINE} | cut -d - -f 1)
TARGET_PLATFORM=$(echo ${TARGET_MACHINE} | cut -d - -f 1)

#
NATIVE_COMPILER_VERSION=$(${NATIVE_COMPILER_C} -dumpversion 2>/dev/null)
TARGET_COMPILER_VERSION=$(${TARGET_COMPILER_C} -dumpversion 2>/dev/null)


#提取本机平台的glibc最大版本。
NATIVE_GLIBC_MAX_VER=$(ldd --version |head -n 1 |rev |cut -d ' ' -f 1 |rev)

#
if [ "${NATIVE_PLATFORM}" == "${TARGET_PLATFORM}" ];then
{
    #提取目标平台的glibc最大版本。
    TARGET_GLIBC_MAX_VER=$(ldd --version |head -n 1 |rev |cut -d ' ' -f 1 |rev)
}
else
{
    #提取目标平台的glibc最大版本。
    if [ -f ${TARGET_COMPILER_SYSROOT}/lib64/libc.so.6 ];then
        TARGET_GLIBC_MAX_VER=$(${TARGET_COMPILER_READELF} -V ${TARGET_COMPILER_SYSROOT}/lib64/libc.so.6 | grep -o 'GLIBC_[0-9]\+\.[0-9]\+' | sort -u -V -r |head -n 1 |cut -d '_' -f 2)
    elif [ -f ${TARGET_COMPILER_SYSROOT}/lib/libc.so.6 ];then
        TARGET_GLIBC_MAX_VER=$(${TARGET_COMPILER_READELF} -V ${TARGET_COMPILER_SYSROOT}/lib/libc.so.6 | grep -o 'GLIBC_[0-9]\+\.[0-9]\+' | sort -u -V -r |head -n 1 |cut -d '_' -f 2)
    fi
}
fi

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
NATIVE_PREFIX_PATH=${RELEASE_PATH}/${NATIVE_MACHINE}/glibc-${NATIVE_GLIBC_MAX_VER}/
TARGET_PREFIX_PATH=${RELEASE_PATH}/${TARGET_MACHINE}/glibc-${TARGET_GLIBC_MAX_VER}/

#################################################################################

#
if [ "${NATIVE_MACHINE}" == "${TARGET_MACHINE}" ];then
{
    #添加第三方库为PKG搜索路径。
    PKG_CONFIG_PATH=${TARGET_PREFIX_PATH}/lib/pkgconfig:${TARGET_PREFIX_PATH}/share/pkgconfig:${PKG_CONFIG_PATH}
}
else
{
    #限制目标平台.pc文件搜索路径范围。
    PKG_CONFIG_LIBDIR=${TARGET_PREFIX_PATH}/lib/pkgconfig:${TARGET_PREFIX_PATH}/share/pkgconfig
    #添加编译输出目录(lib)为动态库的搜索路径，因为有的工具包在编译和安装的过程中会进行本地验证。
    LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${TARGET_PREFIX_PATH}/lib
}
fi

#################################################################################

#生成不存在的路径。
mkdir -p ${NATIVE_PREFIX_PATH}/
mkdir -p ${TARGET_PREFIX_PATH}/
mkdir -p ${BUILD_PATH}/

#导出变量。
export STAPLER_NATIVE_COMPILER_PREFIX=${NATIVE_COMPILER_PREFIX}
export STAPLER_NATIVE_COMPILER_C=${NATIVE_COMPILER_C}
export STAPLER_NATIVE_COMPILER_CXX=${NATIVE_COMPILER_CXX}
export STAPLER_NATIVE_COMPILER_FORTRAN=${NATIVE_COMPILER_FORTRAN}
export STAPLER_NATIVE_COMPILER_SYSROOT=${NATIVE_COMPILER_SYSROOT}
export STAPLER_NATIVE_COMPILER_AR=${NATIVE_COMPILER_AR}
export STAPLER_NATIVE_COMPILER_LD=${NATIVE_COMPILER_LD}
export STAPLER_NATIVE_COMPILER_RANLIB=${NATIVE_COMPILER_RANLIB}
export STAPLER_NATIVE_COMPILER_READELF=${NATIVE_COMPILER_READELF}
#导出变量。
export STAPLER_TARGET_COMPILER_PREFIX=${TARGET_COMPILER_PREFIX}
export STAPLER_TARGET_COMPILER_C=${TARGET_COMPILER_C}
export STAPLER_TARGET_COMPILER_CXX=${TARGET_COMPILER_CXX}
export STAPLER_TARGET_COMPILER_FORTRAN=${TARGET_COMPILER_FORTRAN}
export STAPLER_TARGET_COMPILER_SYSROOT=${TARGET_COMPILER_SYSROOT}
export STAPLER_TARGET_COMPILER_AR=${TARGET_COMPILER_AR}
export STAPLER_TARGET_COMPILER_LD=${TARGET_COMPILER_LD}
export STAPLER_TARGET_COMPILER_RANLIB=${TARGET_COMPILER_RANLIB}
export STAPLER_TARGET_COMPILER_READELF=${TARGET_COMPILER_READELF}
#导出变量。
export STAPLER_NATIVE_MACHINE=${NATIVE_MACHINE}
export STAPLER_TARGET_MACHINE=${TARGET_MACHINE}
export STAPLER_NATIVE_PLATFORM=${NATIVE_PLATFORM}
export STAPLER_TARGET_PLATFORM=${TARGET_PLATFORM}
export STAPLER_NATIVE_COMPILER_VERSION=${NATIVE_COMPILER_VERSION}
export STAPLER_TARGET_COMPILER_VERSION=${TARGET_COMPILER_VERSION}
export STAPLER_NATIVE_PREFIX_PATH=${NATIVE_PREFIX_PATH}
export STAPLER_TARGET_PREFIX_PATH=${TARGET_PREFIX_PATH}
#导出变量。
export STAPLER_BUILD_PATH=${BUILD_PATH}
#
export TMPDIR
export PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
export PKG_CONFIG_LIBDIR=${PKG_CONFIG_LIBDIR}
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}

#
env | grep '^STAPLER_'
echo "TMPDIR=${TMPDIR}"
echo "PKG_CONFIG_LIBDIR=${PKG_CONFIG_LIBDIR}"
echo "PKG_CONFIG_PATH=${PKG_CONFIG_PATH}"
echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"

#等待确认。
while true; do
    read -p "请输入 'yes' 继续: " input
    if [ "$input" = "yes" ]; then
        echo "输入正确，继续执行..."
        break
    else
        echo "输入无效，请重试。"
    fi
done


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


#
chmod +500 ${SHELL_PATH}/kits/FILE/build.sh
${SHELL_PATH}/kits/FILE/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/libvpx/build.sh
${SHELL_PATH}/kits/libvpx/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"

#
chmod +500 ${SHELL_PATH}/kits/abcdk/build.sh
${SHELL_PATH}/kits/abcdk/build.sh
exit_if_error $? "终止。" 1


echo "----------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------"
