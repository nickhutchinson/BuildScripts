#!/bin/bash

PACKAGE_NAME=sip
PACKAGE_MAINTAINER="Nick Hutchinson <nick.hutchinson@thefoundry.co.uk>"
INSTALL_PREFIX=/opt/sip

ARTEFACTS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../Artefacts
TOOLCHAIN_PREFIX=/opt/toolchains/llvm36-gcc49

ROOT="$(pwd)"
STAGING="$ROOT/staging-${PACKAGE_NAME}"
BUILD_SPEC=x86_64-centos6

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

