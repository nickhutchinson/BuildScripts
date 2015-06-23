#!/bin/bash
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/_common.sh"

VERSION=4.9.2
get_url "http://ftpmirror.gnu.org/gcc/gcc-${VERSION}/gcc-${VERSION}.tar.bz2"
extract "$ROOT/gcc-${VERSION}.tar.bz2" "gcc-src"

pushd gcc-src
if [[ ! ( -d mpfr && -d gmp && -d mpc ) ]]; then
    ./contrib/download_prerequisites
fi
popd # gcc-src

config_args=(
    --prefix="/opt/toolchains/$PACKAGE_NAME"
    --enable-shared
    --enable-plugin
    --enable-threads=posix
    --enable-__cxa_atexit
    --enable-clocale=gnu
    --with-system-zlib
    --enable-languages=c,c++,objc,obj-c++
)

mkdir -p gcc-build
pushd gcc-build
run "$ROOT/gcc-src/configure" "${config_args[@]}"
run make "-j$(nproc)"
run env DESTDIR="$STAGING" make install
popd # "gcc-build"
