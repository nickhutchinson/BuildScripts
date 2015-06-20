#!/bin/bash
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/_common.sh"

VERSION_MAJOR=4.8
VERSION=4.8.7
get_url "https://download.qt.io/official_releases/qt/${VERSION_MAJOR}/${VERSION}/qt-everywhere-opensource-src-${VERSION}.tar.gz"
extract "$ROOT/qt-everywhere-opensource-src-${VERSION}.tar.gz" "qt-src"

SRCROOT=$ROOT/qt-src

for build_variant in asan tsan release; do
    mkspec=linux-x86_64-$build_variant
    mkspec_dir=$SRCROOT/mkspecs/$mkspec
    if [[ ! -d "$mkspec_dir" ]]; then
        "$HERE/generate_mkspec.py"                 \
            "--template-dir=$HERE/mkspec_template" \
            "--config=$HERE/config.yaml"           \
            "--build-variant=$build_variant"       \
            -o "$mkspec_dir"
    fi

    prefix=$INSTALL_PREFIX/qt-$VERSION-$build_variant
    config_args=(
        -prefix "$prefix"
        -platform "$mkspec"
        -release
        -system-zlib
        -confirm-license
        -opensource
        -nomake demos
        -nomake examples
        -nomake docs
        -no-qt3support
        -fast
    )

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

return

# # Build package
# fpm_args=(
#     -s dir
#     -t rpm
#     --rpm-compression=xz
#     --rpm-auto-add-directories
#     --maintainer "$PACKAGE_MAINTAINER"
#     -n "$PACKAGE_NAME"
#     -v "$PACKAGE_VERSION"
#     --epoch "$PACKAGE_EPOCH"
# )
# run fpm "${fpm_args[@]}" -C "$STAGING" .
