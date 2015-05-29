#!/bin/bash

PACKAGE_NAME=llvm36-gcc49
PACKAGE_VERSION=3.6.1
INSTALL_PREFIX=/opt/toolchains/$PACKAGE_NAME

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

