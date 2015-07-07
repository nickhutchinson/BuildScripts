#!/bin/bash
# Boost build script. Depends on Python.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/_common.sh"

VERSION=1.46.0

PYTHON_VERSION=2.7.3
PYTHON_VERSION_MAJOR=2.7
PYTHON_ARCHIVE=$ARTEFACTS_DIR/python-${PYTHON_VERSION}-x86_64-centos6.tar.xz
PYTHON_PREFIX=$ROOT/boost-deps/python

BUILD_VARIANTS=(asan+ubsan tsan release debug)

# Fetch, extract and patch.
get_url "http://downloads.sourceforge.net/project/boost/boost/${VERSION}/boost_${VERSION//./_}.tar.bz2"
extract "$ROOT/boost_${VERSION//./_}.tar.bz2" "boost-src"

# Extract Python.
# FIXME: get rid of annoying './' path component from archives; replace with
# archive basename.
run mkdir -p "$PYTHON_PREFIX"
run tar xfv "$PYTHON_ARCHIVE" -C "$PYTHON_PREFIX" --strip-components=2 \
    "./python-${PYTHON_VERSION}-release"

for build_variant in "${BUILD_VARIANTS[@]}"; do
    mkdir -p "boost-build-$build_variant"
    pushd "boost-build-$build_variant"
    run rsync -avh "$ROOT/boost-src/" .

    mkspec_opts=(
        "--template=$HERE/user-config.jam.jinja"
        "--config=$HERE/mkspec_config.yaml"
        "--build-variant=$build_variant"
        -o "user-config.jam"
        -v python_version "$PYTHON_VERSION_MAJOR"
        -v python_executable "$PYTHON_PREFIX/bin/python"
        -v python_include_dir
           "$PYTHON_PREFIX/include/python${PYTHON_VERSION_MAJOR}"
        -v python_lib_dir "$PYTHON_PREFIX/lib"
    )

    run "$HERE/generate_mkspec.py" "${mkspec_opts[@]}"

    prefix=$INSTALL_PREFIX/boost-$VERSION-$build_variant-$PLATFORM_SPEC

    bootstrap_args=(
        --prefix="$STAGING/$prefix"
    )

    build_args=(
        --user-config=user-config.jam
        --layout=tagged # Because Homebrew does, and they do okay.
        "-j$(nproc)"
        -d2 # verbose
        -q # stop at first error
        toolset=clang
        # Boost's precompiled header support for Clang is broken
        # <https://groups.google.com/forum/#!topic/boost-developers-archive/lVPhSeWAJzE>
        pch=off
        debug-symbols=on
        install
    )

    if [[ $build_variant =~ debug ]]; then
        build_args+=(variant=debug)
    else
        build_args+=(variant=release)
    fi

    run ./bootstrap.sh "${bootstrap_args[@]}"
    run ./bjam "${build_args[@]}"
    popd # "boost-build-$build_variant"
done

run tar cvJf                                 \
    "boost-$VERSION-${PLATFORM_SPEC}.tar.xz" \
    -C "$STAGING/$INSTALL_PREFIX" .
