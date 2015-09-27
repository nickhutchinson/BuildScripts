#!/bin/bash

PACKAGE_NAME=llvm37
PACKAGE_EPOCH=1
PACKAGE_VERSION=1.0
INSTALL_PREFIX=/opt/toolchains/$PACKAGE_NAME

ROOT="$(pwd)"
STAGING="$ROOT/staging-${PACKAGE_NAME}"

is_ancient_redhat() {
    test -f /etc/redhat-release && \
        cat /etc/redhat-release | grep -q 'release 5\.[0-9]\+'
}

if is_ancient_redhat; then
    nproc() { getconf _NPROCESSORS_ONLN; }
fi

get_url() {
    basename=$(basename "$1")
    if [[ -f "$basename" ]]; then
        return
    fi
    flags=(-L -C - -fl)
    is_ancient_redhat && flags+=(-k)
    run curl "${flags[@]}" -o "$basename.part" "$@"
    run mv "$basename.part" "$basename"
}

run() {
    >&2 echo "+ $@"
    "$@"
}

extract() {
    run mkdir -p "$2"
    if is_ancient_redhat && [[ ${1: -3} == ".xz" ]]; then
        # CentOS 5's tar doesn't recognise xz.
        run xz -dc "$1" | tar x --strip-components=1 -C "$2"
    else
        run tar xfv "$1" --strip-components=1 -C "$2"
    fi
}
