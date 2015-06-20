#!/bin/bash

PACKAGE_NAME=katana-qt
PACKAGE_EPOCH=0
PACKAGE_VERSION=1.0
PACKAGE_MAINTAINER="Nick Hutchinson <nick.hutchinson@thefoundry.co.uk>"
INSTALL_PREFIX=/opt/katana-deps/qt

TOOLCHAIN_PREFIX=/opt/toolchains/llvm36-gcc49

ROOT="$(pwd)"
STAGING="$ROOT/staging-${PACKAGE_NAME}"

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

