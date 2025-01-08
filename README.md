# 名称

STAPLER(钉书器)

## 简介

为支持在Linux平台中辅助工作创建，集成一些以C/C++语言作为主要编程语言的软件开发工具包，提供本机编译和交叉编译两种能力。


## 准备工作

### Ubuntu|Debian
```
$sudo apt install gcc g++ gfortran make automake libtool libssl-dev pkg-config unzip git texinfo byacc flex bison 
```

### CentOS|Red Hat|RedHat|RHEL|fedora|Amazon|amzn|Oracle
```
$sudo yum install gcc gcc-c++ gcc-gfortran make automake libtool pkgconfig(pkgconf-pkg-config) openssl-devel unzip git texinfo byacc flex bison
```

### 查看帮助
```
$./build.sh -h
```

### 本机编译
```
$./build.sh 
```

### 交叉编译
```
$./build.sh -e TARGET_COMPILER_HOME=/toolchain/xxx/ -e TARGET_COMPILER_PREFIX=/toolchain/xxx/machine-
```