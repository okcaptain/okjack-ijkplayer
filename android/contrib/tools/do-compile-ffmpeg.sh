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
FF_BUILD_OPT=$2
echo "FF_ARCH=$FF_ARCH"
echo "FF_BUILD_OPT=$FF_BUILD_OPT"
if [ -z "$FF_ARCH" ]; then
    echo "You must specific an architecture 'arm, armv7a, x86, ...'."
    echo ""
    exit 1
fi


FF_BUILD_ROOT=`pwd`

FF_BUILD_NAME=
FF_SOURCE=
FF_CROSS_PREFIX=
FF_DEP_OPENSSL_INC=
FF_DEP_OPENSSL_LIB=

FF_DEP_LIBSOXR_INC=
FF_DEP_LIBSOXR_LIB=

FF_CFG_FLAGS=

FF_EXTRA_CFLAGS=
FF_EXTRA_LDFLAGS=
FF_DEP_LIBS=


#--------------------
echo ""
echo "--------------------"
echo "[*] make NDK standalone toolchain"
echo "--------------------"
. ./tools/do-detect-env.sh


FF_MAKE_FLAGS=$IJK_MAKE_FLAG
FF_CC=$IJK_CC

if [ "$FF_ARCH" = "armv7a" ]; then
    FF_ANDROID_API=16
    PLATFORM=arm-linux-androideabi
    PLATFORM_T=armv7a-linux-androideabi

    FF_BUILD_NAME=ffmpeg-armv7a
    FF_BUILD_NAME_LIBAV3AD=libav3ad-armv7a
    FF_BUILD_NAME_LIBUAVS3D=libuavs3d-armv7a
    FF_BUILD_NAME_OPENSSL=openssl-armv7a
    FF_BUILD_NAME_LIBSOXR=libsoxr-armv7a
    FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME

    FF_CROSS_PREFIX=arm-linux-androideabi
    FF_TOOLCHAIN_NAME=${FF_CROSS_PREFIX}-${FF_GCC_VER}

    FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=arm --cpu=cortex-a8"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-neon"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-thumb"

    FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS -march=armv7-a -mcpu=cortex-a8 -mfpu=vfpv3-d16 -mfloat-abi=softfp -mthumb"
    FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS -Wl,--fix-cortex-a8"


elif [ "$FF_ARCH" = "arm64" ]; then
  FF_ANDROID_API=21
  PLATFORM=aarch64-linux-android
  PLATFORM_T=aarch64-linux-android

  FF_BUILD_NAME=ffmpeg-arm64
  FF_BUILD_NAME_LIBAV3AD=libav3ad-arm64
  FF_BUILD_NAME_LIBUAVS3D=libuavs3d-arm64
  FF_BUILD_NAME_OPENSSL=openssl-arm64
  FF_BUILD_NAME_LIBSOXR=libsoxr-arm64
  FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME

  FF_CROSS_PREFIX=aarch64-linux-android
  FF_TOOLCHAIN_NAME=${FF_CROSS_PREFIX}-${FF_GCC_64_VER}

  FF_CFG_FLAGS="$FF_CFG_FLAGS --arch=aarch64 --enable-yasm"

  FF_EXTRA_CFLAGS="$FF_EXTRA_CFLAGS"
  FF_EXTRA_LDFLAGS="$FF_EXTRA_LDFLAGS"


else
    echo "unknown architecture $FF_ARCH";
    exit 1
fi

echo $FF_SOURCE
ls -al $FF_SOURCE

if [ ! -d $FF_SOURCE ]; then
    echo ""
    echo "!! ERROR"
    echo "!! Can not find FFmpeg directory for $FF_BUILD_NAME"
    echo "!! Run 'sh init-android.sh' first"
    echo ""
    exit 1
fi
FF_TOOLCHAIN_PATH=$FF_BUILD_ROOT/build/$FF_BUILD_NAME/toolchain
FF_MAKE_TOOLCHAIN_FLAGS="$FF_MAKE_TOOLCHAIN_FLAGS --install-dir=$FF_TOOLCHAIN_PATH"

FF_SYSROOT=$FF_TOOLCHAIN_PATH/sysroot

FF_PREFIX=$FF_BUILD_ROOT/build/$FF_BUILD_NAME/output
FF_DEP_OPENSSL_INC=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_OPENSSL/output/include
FF_DEP_OPENSSL_LIB=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_OPENSSL/output/lib
FF_DEP_LIBSOXR_INC=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_LIBSOXR/output/include
FF_DEP_LIBSOXR_LIB=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_LIBSOXR/output/lib
FF_DEP_LIBUAVS3D_INC=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_LIBUAVS3D/output/include
FF_DEP_LIBUAVS3D_LIB=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_LIBUAVS3D/output/lib
FF_DEP_LIBAV3AD_INC=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_LIBAV3AD/output/include
FF_DEP_LIBAV3AD_LIB=$FF_BUILD_ROOT/build/$FF_BUILD_NAME_LIBAV3AD/output/lib

case "$UNAME_S" in
    CYGWIN_NT-*)
        FF_PREFIX="$(cygpath -am $FF_PREFIX)"
    ;;
esac


mkdir -p $FF_PREFIX

FF_TOOLCHAIN_TOUCH="$FF_TOOLCHAIN_PATH/touch"

if [ -d "$FF_TOOLCHAIN_PATH" ]; then
    rm -rf $FF_TOOLCHAIN_PATH
fi
if [ "$FF_CC" = "gcc" ]; then
    if [ ! -f "$FF_TOOLCHAIN_TOUCH" ]; then
        $ANDROID_NDK/build/tools/make-standalone-toolchain.sh \
            $FF_MAKE_TOOLCHAIN_FLAGS \
            --platform=android-$FF_ANDROID_PLATFORM \
            --toolchain=$FF_TOOLCHAIN_NAME
    fi
else
    ARCH=$FF_ARCH
    if [ "$FF_ARCH" = "armv7a" ]; then
        ARCH=arm
    fi
    FF_MAKE_TOOLCHAIN_FLAGS="--install-dir $FF_TOOLCHAIN_PATH --arch $ARCH --api $FF_ANDROID_API"
    python $ANDROID_NDK/build/tools/make_standalone_toolchain.py \
        $FF_MAKE_TOOLCHAIN_FLAGS
fi


#--------------------
echo ""
echo "--------------------"
echo "[*] check ffmpeg env"
echo "--------------------"
FF_TOOLCHAIN_PATH_BIN=$FF_TOOLCHAIN_PATH/bin
export PATH=$FF_TOOLCHAIN_PATH_BIN:$PATH
#export CC="ccache ${FF_CROSS_PREFIX}-gcc"
export CC=${FF_CROSS_PREFIX}-${FF_CC}
export LD=${FF_CROSS_PREFIX}-ld
export AR=${FF_CROSS_PREFIX}-ar
export STRIP=${FF_CROSS_PREFIX}-strip

FF_CFLAGS="-O3 -Wall -pipe \
    -ffast-math \
    -fstrict-aliasing -Werror=strict-aliasing \
    -DANDROID -DNDEBUG"

# cause av_strlcpy crash with gcc4.7, gcc4.8
# -fmodulo-sched -fmodulo-sched-allow-regmoves

# --enable-thumb is OK
#FF_CFLAGS="$FF_CFLAGS -mthumb"

# not necessary
#FF_CFLAGS="$FF_CFLAGS -finline-limit=300"

export COMMON_FF_CFG_FLAGS=
. $FF_BUILD_ROOT/../../config/module.sh


#--------------------
# with openssl
if [ -f "${FF_DEP_OPENSSL_LIB}/libssl.a" ]; then
    echo "OpenSSL detected"
# FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-nonfree"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-openssl"

    FF_CFLAGS="$FF_CFLAGS -I${FF_DEP_OPENSSL_INC}"
    FF_DEP_LIBS="$FF_DEP_LIBS -L${FF_DEP_OPENSSL_LIB} -lssl -lcrypto"
fi

if [ -f "${FF_DEP_LIBSOXR_LIB}/libsoxr.a" ]; then
    echo "libsoxr detected"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-libsoxr"

    FF_CFLAGS="$FF_CFLAGS -I${FF_DEP_LIBSOXR_INC}"
    FF_DEP_LIBS="$FF_DEP_LIBS -L${FF_DEP_LIBSOXR_LIB} -lsoxr"
fi

if [ -f "${FF_DEP_LIBUAVS3D_LIB}/libuavs3d.a" ]; then
    echo "libuavs3d detected"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-libuavs3d"

    FF_CFLAGS="$FF_CFLAGS -I${FF_DEP_LIBUAVS3D_INC}"
    FF_DEP_LIBS="$FF_DEP_LIBS -L${FF_DEP_LIBUAVS3D_LIB} -luavs3d"
fi

if [ -f "${FF_DEP_LIBAV3AD_LIB}/libav3ad.so" ]; then
    echo "libav3ad detected"

    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-libav3ad"

    FF_CFLAGS="$FF_CFLAGS -I${FF_DEP_LIBAV3AD_INC}"
    FF_DEP_LIBS="$FF_DEP_LIBS -L${FF_DEP_LIBAV3AD_LIB} -lav3ad -lm"
fi




FF_CFG_FLAGS="$FF_CFG_FLAGS $COMMON_FF_CFG_FLAGS"


# Advanced options (experts only):
FF_CFG_FLAGS="$FF_CFG_FLAGS --cross-prefix=${FF_CROSS_PREFIX}-"
FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-cross-compile"
FF_CFG_FLAGS="$FF_CFG_FLAGS --target-os=linux"
FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-pic"
# FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-symver"

if [ "$FF_ARCH" = "x86" ]; then
    FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-asm"
else
    # Optimization options (experts only):
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-asm"
    FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-inline-asm"
fi

case "$FF_BUILD_OPT" in
    debug)
        FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-optimizations"
        FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-debug"
        FF_CFG_FLAGS="$FF_CFG_FLAGS --disable-small"
    ;;
    *)
        FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-optimizations"
        FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-debug"
        FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-small"
    ;;
esac

#--------------------
echo ""
echo "--------------------"
echo "[*] configurate ffmpeg"
echo "--------------------"
cd $FF_SOURCE
ls -al $FF_SOURCE
if [ -f "./config.h" ]; then
    echo 'reuse configure'
else
    echo $CC
    echo "./configure $FF_CFG_FLAGS --extra-cflags=$FF_CFLAGS $FF_EXTRA_CFLAGS --extra-ldflags=$FF_DEP_LIBS $FF_EXTRA_LDFLAGS"
    ls -al ./
    chmod +x ./configure
    ./configure $FF_CFG_FLAGS \
            --disable-static \
            --enable-shared \
            --extra-cflags="$FF_CFLAGS $FF_EXTRA_CFLAGS" \
            --extra-ldflags="$FF_DEP_LIBS $FF_EXTRA_LDFLAGS" || cat ffbuild/config.log
fi

#--------------------
echo ""
echo "--------------------"
echo "[*] compile ffmpeg"
echo "--------------------"
make $FF_MAKE_FLAGS
make DESTDIR="$FF_PREFIX" install

ls -al $FF_PREFIX
ls -al $FF_PREFIX/usr
if [ -d "${FF_PREFIX}/usr/local" ]; then
    ls -al $FF_PREFIX/usr/local
else
    echo "${FF_PREFIX}/usr/local"
fi

mkdir -p $FF_PREFIX/usr/local/include/libffmpeg
cp -f config.h $FF_PREFIX/usr/local/include/libffmpeg/config.h
