#!/bin/bash
PACKAGE_NAME=pyqt
PACKAGE_MAINTAINER="Nick Hutchinson <nick.hutchinson@thefoundry.co.uk>"

TOOLCHAIN_PREFIX=/opt/toolchains/llvm36-gcc49
CC=$TOOLCHAIN_PREFIX/bin/clang
CXX=$TOOLCHAIN_PREFIX/bin/clang++

ARTEFACTS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../Artefacts
BUILD_SPEC=x86_64-centos6
INSTALL_PREFIX=/opt/${PACKAGE_NAME}
ROOT="$(pwd)"
STAGING=$ROOT/${PACKAGE_NAME}-staging

get_url() {
    basename=$(basename "$1")
    if [[ -f "$basename" ]]; then
        return
    fi
    run curl -C - -fL -o "$basename.part" "$@"
    run mv "$basename.part" "$basename"
}

run() {
    >&2 echo "+ $@"
    "$@"
}

extract() {
    run mkdir -p "$2"
    run tar xfv "$1" --strip-components=1 -C "$2"
}
