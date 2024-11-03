#! /usr/bin/env bash
#
# Copyright (C) 2014 Miguel Botón <waninkoko@gmail.com>
# Copyright (C) 2014 Zhang Rui <bbcallen@gmail.com>
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

#--------------------
set -e

if [ -z "$ANDROID_NDK" ]; then
    echo "You must define ANDROID_NDK before starting."
    echo "They must point to your NDK directories.\n"
    exit 1
fi

#--------------------
# common defines
FF_ARCH=$1
if [ -z "$FF_ARCH" ]; then
    echo "You must specific an architecture 'arm, armv7a, x86, ...'.\n"
    exit 1
fi


FF_BUILD_ROOT=`pwd`
FF_ANDROID_PLATFORM=android-16
FF_ANDROID_API=16


#--------------------
echo ""
echo "--------------------"
echo "[*] make NDK standalone toolchain"
echo "--------------------"
. ./tools/do-detect-env.sh



build() {
  if [ "$FF_ARCH" = "armv7a" ]; then
    CPU=arm
    API=16
    PLATFORM=arm-linux-androideabi
    FF_BUILD_NAME=openssl-armv7a
  elif [ "$FF_ARCH" = "arm64" ]; then
    CPU=arm64
    API=21
    PLATFORM=aarch64-linux-android
    FF_BUILD_NAME=openssl-arm64
  else
      echo "unknown architecture $FF_ARCH";
      exit 1
  fi

  FF_SOURCE=$FF_BUILD_ROOT/$FF_BUILD_NAME
  FF_PREFIX=$FF_BUILD_ROOT/build/$FF_BUILD_NAME/output
  mkdir -p $FF_PREFIX
  export PATH=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin:$ANDROID_NDK/toolchains/$PLATFORM-4.9/prebuilt/linux-x86_64/bin:$PATH
  cd $FF_SOURCE
  ls -al $ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin
  ls -al $ANDROID_NDK/toolchains/$PLATFORM-4.9/prebuilt/linux-x86_64/bin
  ./Configure android-$CPU -D__ANDROID_API__=$API no-shared zlib-dynamic --prefix=$FF_PREFIX --openssldir=$FF_PREFIX

  make
  make install
}

build
