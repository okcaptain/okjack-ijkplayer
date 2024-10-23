#! /usr/bin/env bash
#
# Copyright (C) 2013-2014 Zhang Rui <bbcallen@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This script is based on projects below
# https://github.com/yixia/FFmpeg-Android
# http://git.videolan.org/?p=vlc-ports/android.git;a=summary

#--------------------
echo "===================="
echo "[*] check env $1"
echo "===================="
set -e


#--------------------
# common defines
FF_ARCH=$1
echo "FF_ARCH=$FF_ARCH"
if [ -z "$FF_ARCH" ]; then
    echo "You must specific an architecture 'arm, armv7a, x86, ...'."
    echo ""
    exit 1
fi


FF_BUILD_ROOT=`pwd`
FF_ANDROID_PLATFORM=android-19
FF_ANDROID_ABI=armeabi-v7a


FF_BUILD_NAME=
FF_SOURCE=

#--------------------
echo ""
echo "--------------------"
echo "[*] make NDK standalone toolchain"
echo "--------------------"
. ./tools/do-detect-env.sh


#----- armv7a begin -----
if [ "$FF_ARCH" = "armv7a" ]; then
    FF_BUILD_NAME=libuavs3d-armv7a
    FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME
    FF_ANDROID_ABI=armeabi-v7a



elif [ "$FF_ARCH" = "armv5" ]; then
    FF_BUILD_NAME=libuavs3d-armv5
    FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME
    FF_ANDROID_ABI=armeabi-v7a


elif [ "$FF_ARCH" = "x86" ]; then
    FF_BUILD_NAME=libuavs3d-x86
    FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME
    FF_ANDROID_ABI=x86

elif [ "$FF_ARCH" = "x86_64" ]; then
    FF_ANDROID_PLATFORM=android-21

    FF_BUILD_NAME=libuavs3d-x86_64
    FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME
    FF_ANDROID_ABI=x86_64


elif [ "$FF_ARCH" = "arm64" ]; then
    FF_ANDROID_PLATFORM=android-21

    FF_BUILD_NAME=libuavs3d-arm64
    FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME
    FF_ANDROID_ABI=arm64-v8a


else
    echo "unknown architecture $FF_ARCH";
    exit 1
fi

FF_TOOLCHAIN_PATH=$FF_BUILD_ROOT/build/$FF_BUILD_NAME/toolchain

FF_SYSROOT=$FF_TOOLCHAIN_PATH/sysroot
FF_PREFIX=$FF_BUILD_ROOT/build/$FF_BUILD_NAME/output

mkdir -p $FF_PREFIX
# mkdir -p $FF_SYSROOT

#--------------------
echo ""
echo "--------------------"
echo "[*] make NDK standalone toolchain"
echo "--------------------"
. ./tools/do-detect-env.sh
FF_MAKE_TOOLCHAIN_FLAGS=$IJK_MAKE_TOOLCHAIN_FLAGS
FF_MAKE_FLAGS=$IJK_MAKE_FLAG


FF_MAKE_TOOLCHAIN_FLAGS="$FF_MAKE_TOOLCHAIN_FLAGS --install-dir=$FF_TOOLCHAIN_PATH"
FF_TOOLCHAIN_TOUCH="$FF_TOOLCHAIN_PATH/touch"
if [ ! -f "$FF_TOOLCHAIN_TOUCH" ]; then
    $ANDROID_NDK/build/tools/make-standalone-toolchain.sh \
        $FF_MAKE_TOOLCHAIN_FLAGS \
        --platform=$FF_ANDROID_PLATFORM \
        --toolchain=$FF_TOOLCHAIN_NAME
    touch $FF_TOOLCHAIN_TOUCH;
fi

#--------------------
echo ""
echo "--------------------"
echo "[*] check libuavs3d env"
echo "--------------------"
export PATH=$FF_TOOLCHAIN_PATH/bin:$PATH


cd $FF_SOURCE


CMAKE_EXECUTABLE=$ANDROID_SDK/cmake/3.18.1/bin/cmake

ls -al .

$CMAKE_EXECUTABLE . \
 -DCMAKE_VERBOSE_MAKEFILE=ON \
 -DCMAKE_ANDROID_ARCH_ABI=$FF_ANDROID_ABI \
 -DANDROID_PLATFORM=$FF_ANDROID_PLATFORM \
 -DPROJECT_ABI=$FF_ANDROID_ABI \
 -DANDROID_ABI=$FF_ANDROID_ABI \
 -DANDROID_NDK=$ANDROID_NDK \
 -DCMAKE_ANDROID_NDK=$ANDROID_NDK \
 -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
 -DCMAKE_INSTALL_PREFIX=$FF_PREFIX \
 -DCOMPILE_10BIT=1

make clean
make
make install


