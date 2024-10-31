#! /usr/bin/env bash
#
# Copyright (C) 2013-2015 Bilibili
# Copyright (C) 2013-2015 Zhang Rui <bbcallen@gmail.com>
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

IJK_LIBUAVS3D_UPSTREAM=https://github.com/okcaptain/avs3a.git
IJK_LIBUAVS3D_FORK=https://github.com/okcaptain/avs3a.git
IJK_LIBUAVS3D_COMMIT=master
IJK_LIBUAVS3D_LOCAL_REPO=extra/libav3ad

set -e
TOOLS=tools

git --version

echo "== pull libav3ad base =="
sh $TOOLS/pull-repo-base.sh $IJK_LIBUAVS3D_UPSTREAM $IJK_LIBUAVS3D_LOCAL_REPO

function pull_fork()
{
    echo "== pull libav3ad fork $1 =="
    sh $TOOLS/pull-repo-ref.sh $IJK_LIBUAVS3D_FORK android/contrib/libav3ad-$1 ${IJK_LIBUAVS3D_LOCAL_REPO}
    cd android/contrib/libav3ad-$1
    git checkout ${IJK_LIBUAVS3D_COMMIT} -B ijkplayer
    cd -
}

pull_fork "armv7a"
#pull_fork "arm64"
#pull_fork "x86"
#pull_fork "x86_64"
