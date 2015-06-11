#!/bin/bash
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/_common.sh"

VERSION=2.7.10
get_url "https://www.python.org/ftp/python/${VERSION}/Python-${VERSION}.tar.xz"
extract "$ROOT/Python-${VERSION}.tar.xz" "python-src"

# Patches to make relocatable
mkdir -p python-patches
pushd python-patches
get_url https://raw.githubusercontent.com/Infinidat/relocatable-python/develop/src/patches/python-2.7.8-sysconfig.py.patch
get_url https://raw.githubusercontent.com/Infinidat/relocatable-python/develop/src/patches/python-2.7.8-disutils-sysconfig.py.patch
get_url https://raw.githubusercontent.com/Infinidat/relocatable-python/develop/src/patches/python-2.7.8-pythonhome-pythonrun.c.patch
get_url https://raw.githubusercontent.com/Infinidat/relocatable-python/develop/src/patches/python-2.7.8-redhat-lib64.patch
get_url https://raw.githubusercontent.com/Infinidat/relocatable-python/develop/src/patches/python-2.7.8-linux-symlink.patch
popd


pushd python-src
for f in ../python-patches/*.patch; do
    patch -N -p1 < "$f"
done
popd

config_args=(
    --prefix="/opt/toolchains/$PACKAGE_NAME"
    --libdir="/opt/toolchains/$PACKAGE_NAME/lib64"
    --enable-shared
    --with-system-expat
    --with-system-ffi
    --enable-unicode=ucs4
    'LDFLAGS=-Wl,-rpath,\$$ORIGIN/../lib64' # make relocatable
)

mkdir -p python-build
pushd python-build
run "$ROOT/python-src/configure" "${config_args[@]}"
run make "-j$(nproc)"
run env DESTDIR="$STAGING" make install
popd # "python-build"
