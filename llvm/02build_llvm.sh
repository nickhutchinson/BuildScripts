#!/bin/bash
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/_common.sh"

CC=$STAGING/$INSTALL_PREFIX/bin/gcc
CXX=$STAGING/$INSTALL_PREFIX/bin/g++
GCC_LIBDIR=$STAGING/$INSTALL_PREFIX/lib64

VERSION=$PACKAGE_VERSION

get_url "http://llvm.org/releases/${VERSION}/llvm-${VERSION}.src.tar.xz"
get_url "http://llvm.org/releases/${VERSION}/cfe-${VERSION}.src.tar.xz"
get_url "http://llvm.org/releases/${VERSION}/compiler-rt-${VERSION}.src.tar.xz"
get_url "http://llvm.org/releases/${VERSION}/clang-tools-extra-${VERSION}.src.tar.xz"

extract "$ROOT/llvm-${VERSION}.src.tar.xz" "llvm-src"
extract "$ROOT/cfe-${VERSION}.src.tar.xz" "llvm-src/tools/clang"
extract "$ROOT/clang-tools-extra-${VERSION}.src.tar.xz" "llvm-src/tools/clang/tools/extra"
extract "$ROOT/compiler-rt-${VERSION}.src.tar.xz" "llvm-src/projects/compiler-rt"

cmake_config_args=(
    "-DCMAKE_C_COMPILER=$CC"
    "-DCMAKE_CXX_COMPILER=$CXX"
    "-DLLVM_LIBDIR_SUFFIX=64"
    "-DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX"
    "-DBUILD_SHARED_LIBS=1"
    "-DCMAKE_BUILD_TYPE=Release"
    "-GNinja"
    "$ROOT/llvm-src"
)

mkdir -p llvm-build
pushd llvm-build
export LD_LIBRARY_PATH=$GCC_LIBDIR:${LD_LIBRARY_PATH:-}
run scl enable python27 -- cmake "${cmake_config_args[@]}"
run scl enable python27 -- ninja "-j$(nproc)"
run scl enable python27 -- env DESTDIR="$STAGING" ninja install
popd # "llvm-build"
