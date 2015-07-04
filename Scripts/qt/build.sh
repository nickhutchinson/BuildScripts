#!/bin/bash
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/_common.sh"

VERSION_MAJOR=4.8
VERSION=4.8.5
get_url "https://download.qt.io/archive/qt/${VERSION_MAJOR}/${VERSION}/qt-everywhere-opensource-src-${VERSION}.tar.gz"
extract "$ROOT/qt-everywhere-opensource-src-${VERSION}.tar.gz" "qt-src"

SRCROOT=$ROOT/qt-src

pushd qt-src
for f in "$HERE/patches/"*.patch; do
    patch -N -p1 < "$f"
done
popd

for build_variant in asan+ubsan tsan release debug; do
    mkspec=linux-x86_64-$build_variant
    mkspec_dir=$SRCROOT/mkspecs/$mkspec
    if [[ ! -d "$mkspec_dir" ]]; then
        mkspec_opts=(
            "--template=$HERE/mkspec_template"
            "--config=$HERE/config.yaml"
            "--build-variant=$build_variant"
            -o "$mkspec_dir"
        )

        if [[ $build_variant =~ san ]]; then
            mkspec_opts+=(
                -v CFLAGS "-fsanitize-blacklist=$HERE/sanitizer-blacklist.txt"
                -v CXXFLAGS "-fsanitize-blacklist=$HERE/sanitizer-blacklist.txt"
                -v LDFLAGS "-fsanitize-blacklist=$HERE/sanitizer-blacklist.txt"
            )
        fi

        run "$HERE/generate_mkspec.py" "${mkspec_opts[@]}"
    fi

    prefix=$INSTALL_PREFIX/qt-$VERSION-$build_variant
    config_args=(
        -prefix "$prefix"
        -platform "$mkspec"
        -release
        -system-zlib
        -confirm-license
        -opensource
        -fast
        -nomake demos
        -nomake examples
        -nomake docs
        -no-qt3support
    )

    if [[ $build_variant =~ debug ]]; then
        config_args+=(-debug)
    else
        config_args+=(-release)
    fi

    if [[ $build_variant =~ asan ]]; then
        export ASAN_OPTIONS=detect_leaks=0
    fi

    mkdir -p "qt-build-$build_variant"
    pushd "qt-build-$build_variant"
    run "$SRCROOT/configure" "${config_args[@]}"
    run make "-j$(nproc)"
    run env INSTALL_ROOT="$STAGING" make install
    popd # "qt-build-$build_variant"

    unset ASAN_OPTIONS
done
