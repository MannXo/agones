#!/usr/bin/env bash

# Copyright Contributors to Agones a Series of LF Projects, LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -ex
GO111MODULE=off
DIR=/go/src/agones.dev/agones/test/sdk/cpp/
echo "$DIR"/sdk

BUILD_TYPE=Release
BUILD_DIR=.build
CXX_FLAGS=""
if [[ "$SANITIZERS" == "true" ]]
then
    BUILD_TYPE=RelWithDebInfo
    BUILD_DIR=.build-sanitizers
    CXX_FLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer"
fi

# Copy all CPP SDK files into a new directory
if [[ ! -d $DIR/sdk ]]
then
    mkdir -p "$DIR"/sdk
    cp -r /go/src/agones.dev/agones/sdks/cpp/* $DIR/sdk
fi
if [[ ! -d $DIR/sdk/$BUILD_DIR ]]
then
    mkdir -p "$DIR"/sdk/$BUILD_DIR
    cd $DIR/sdk/$BUILD_DIR
    cmake .. -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DCMAKE_CXX_FLAGS="$CXX_FLAGS" -DAGONES_SILENT_OUTPUT=OFF \
      -DCMAKE_INSTALL_PREFIX=$DIR/sdk/$BUILD_DIR -G "Unix Makefiles" -Wno-dev
else
    echo "Directory with cpp SDK third party dependencies \
has already built - using cached version. \
Use make clean-sdk-conformance-tests if you want to start from scratch"
fi
cd $DIR/sdk/$BUILD_DIR
cmake --build .  --target install -j$(nproc)
cd $DIR && mkdir -p $BUILD_DIR && cd $BUILD_DIR
cmake .. -G "Unix Makefiles" \
   -DCMAKE_PREFIX_PATH=$DIR/sdk/$BUILD_DIR \
   -Dagones_DIR=$DIR/sdk/$BUILD_DIR/agones/cmake \
   -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DCMAKE_CXX_FLAGS="$CXX_FLAGS" -DCMAKE_INSTALL_PREFIX=.bin
cmake --build . --target install -j$(nproc)
