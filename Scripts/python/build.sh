#!/bin/bash
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/_common.sh"

VERSION=2.7.3
get_url "https://www.python.org/ftp/python/${VERSION}/Python-${VERSION}.tar.xz"
extract "$ROOT/Python-${VERSION}.tar.xz" "python-src"

# We want to use *clang++* to drive the linking, so the C++ bits of the
# sanitizer runtime get linked in. Our python executable must be able to host
# ASan/TSan-ified Python modules. Adding '-x c' to CFLAGS means we still
# compile C files as C.
export CC=$TOOLCHAIN_PREFIX/bin/clang++
export CXX=$TOOLCHAIN_PREFIX/bin/clang++

# Map of build variant => requried compiler flags
BUILD_VARIANTS=(
    release     "-g"
    asan+ubsan  "-g -fsanitize=address,undefined -fno-sanitize=alignment,shift"
    tsan        "-g -fsanitize=thread -fsanitize-blacklist=$HERE/tsan-blacklist.txt"
)

for ((i=0; i < "${#BUILD_VARIANTS[@]}"; i+=2)); do
    variant=${BUILD_VARIANTS[$i]}
    flags=${BUILD_VARIANTS[$(($i + 1))]}

    prefix=$INSTALL_PREFIX/python-$VERSION-$variant

    # -fno-common: in C, don't emit globals as common symbols; allows ASan to
    # instrument them
    # -fno-omit-frame-pointer: ASan's default stack unwind uses frame pointers
    # (although you can pass "fast_unwind_on_malloc=0" as an ASAN_OPTIONS
    # option to use an alternate frame walker).
    # -rpath: Makes python binary relocatable.
    cflags="$flags -fno-common -fno-omit-frame-pointer -x c --gcc-toolchain=/usr"
    cxxflags="$flags -fno-common -fno-omit-frame-pointer --gcc-toolchain=/usr"
    ldflags="$flags -Wl,-rpath,\\\$\$ORIGIN/../lib64 --gcc-toolchain=/usr"

    config_args=(
        --prefix="$prefix"
        --libdir="$prefix/lib64"
        --enable-shared
        --with-system-expat
        --with-system-ffi
        --enable-unicode=ucs4
    )

    if [[ $variant =~ asan ]]; then
        # Some ./configure tests fail without disabling leak checks.
        export ASAN_OPTIONS=detect_leaks=0
        config_args+=(--without-pymalloc)
    fi

    config_args+=( CFLAGS="$cflags" CXXFLAGS="$cxxflags" LDFLAGS="$ldflags" )

    mkdir -p "python-build-$variant"
    pushd "python-build-$variant"
    run "$ROOT/python-src/configure" "${config_args[@]}"
    run make "-j$(nproc)"
    run env DESTDIR="$STAGING" make install
    popd # "python-build-$variant"

    if [[ $variant =~ asan ]]; then
        unset ASAN_OPTIONS
    fi
done
