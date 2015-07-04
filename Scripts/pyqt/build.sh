#!/bin/bash
# PyQt build script. Depends on both SIP and Qt itself.
#
# IMPORTANT NOTE:
# PyQt's a little precious: it want to build itself with the exact same flags
# Qt was built with. This requires some special handling to ensure absolute
# paths from the Qt build -- paths that may no longer exist -- don't give us
# grief. It's not perfect -- Qt is not trivially relocatable, and there still
# seem to be some spurious linker paths getting into the PyQt build
# ("/opt/katana-deps/qt/..."), but I think that's fairly harmless.
################################################################################
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/_common.sh"

VERSION=4.10.4

PYTHON_VERSION=2.7.3
PYTHON_VERSION_MAJOR=2.7
PYTHON_ARCHIVE=$ARTEFACTS_DIR/python-${PYTHON_VERSION}-x86_64-centos6.tar.xz
PYTHON_PREFIX=$ROOT/pyqt-deps/python

SIP_VERSION=4.15.5
SIP_ARCHIVE=$ARTEFACTS_DIR/sip-${SIP_VERSION}-x86_64-centos6.tar.xz
SIP_PREFIX=$ROOT/pyqt-deps/sip

QT_VERSION=4.8.5
QT_ARCHIVE=$ARTEFACTS_DIR/qt-${QT_VERSION}-x86_64-centos6.tar.xz
QT_PREFIX_BASE=$ROOT/pyqt-deps/qt

# TODO: debug variant also? Need to figure out how to strip optimisation flags;
# the 'QMAKE_CXXFLAGS ~= ...' trick used below doesn't appear to work for some
# reason.
BUILD_VARIANTS=(asan+ubsan tsan release debug)

# Fetch, extract and patch.
get_url "http://downloads.sourceforge.net/project/pyqt/PyQt4/PyQt-${VERSION}/PyQt-x11-gpl-${VERSION}.tar.gz"
extract "$ROOT/PyQt-x11-gpl-${VERSION}.tar.gz" "pyqt-src"

pushd pyqt-src
for f in "$HERE/patches/"*.patch; do
    patch -N -p1 < "$f"
done
popd

# Extract Python.
run mkdir -p "$PYTHON_PREFIX"
run tar xfv "$PYTHON_ARCHIVE" -C "$PYTHON_PREFIX" --strip-components=2 \
    "./python-${PYTHON_VERSION}-release"

# Extract SIP.
run mkdir -p "$SIP_PREFIX"
run tar xfv "$SIP_ARCHIVE" -C "$SIP_PREFIX" --strip-components=2 \
    "./sip-${SIP_VERSION}-release"

# Extract Qt. NOTE: PyQt's build system tries to build with the exact same
# flags Qt was built with, using some creepy introspection.
for build_variant in "${BUILD_VARIANTS[@]}"; do
    run mkdir -p "$QT_PREFIX_BASE/$build_variant"
    run tar xfv "$QT_ARCHIVE" -C "$QT_PREFIX_BASE/$build_variant" \
        --strip-components=2                                      \
        "./qt-${QT_VERSION}-${build_variant}"

    # Required to avoid using hard-coded absolute paths in the binary.
    # <http://doc.qt.io/qt-4.8/qt-conf.html>
    # FIXME: Do as a post-build step when building Qt itself?
    echo -e "[Paths]\nPrefix = .." \
        > "$QT_PREFIX_BASE/$build_variant/bin/qt.conf"
done
# FIXME: get rid of annoying './' path component from archives; replace with
# archive basename.

for build_variant in "${BUILD_VARIANTS[@]}"; do
    mkdir -p "pyqt-build-$build_variant"
    pushd "pyqt-build-$build_variant"
    run rsync -avh "$ROOT/pyqt-src/" .

    prefix=$INSTALL_PREFIX/pyqt-$VERSION-$build_variant
    config_args=(
        --confirm-license
        --bindir "$prefix/bin"
        --destdir "$prefix/lib"
        --designer-plugindir "$prefix/plugins"
        --sipdir "$prefix/sip"
        --qmake "$QT_PREFIX_BASE/$build_variant/bin/qmake"
        --sip "$SIP_PREFIX/bin/sip"
        --sip-incdir "$SIP_PREFIX/include/python${PYTHON_VERSION_MAJOR}"
        --verbose
    )

    if [[ $build_variant =~ debug ]]; then
        config_args+=(--debug)
    fi

    config_args+=(
        # Stop compiler flags and related variables from Qt giving us grief due
        # to absolute paths.
        QMAKE_CC="$CC"
        QMAKE_CXX="$CXX"
        QMAKE_LINK="$CXX"
        QMAKE_LINK_SHLIB="$CXX"
        'QMAKE_CFLAGS ~= s/-fsanitize-blacklist=.+/'
        'QMAKE_CXXFLAGS ~= s/-fsanitize-blacklist=.+/'
        'QMAKE_LFLAGS ~= s/-fsanitize-blacklist=.+/'

        # Disable stripping
        QMAKE_STRIP=
    )

    # LD_LIBRARY_PATH needed so executables built by confgure-ng.py can find Qt
    # libs.
    run env LD_LIBRARY_PATH="$QT_PREFIX_BASE/$build_variant/lib" \
        ASAN_OPTIONS=detect_leaks=0                              \
        "$PYTHON_PREFIX/bin/python"                              \
        "configure-ng.py"                                        \
        "${config_args[@]}"
    run make "-j$(nproc)"
    run env INSTALL_ROOT="$STAGING" make install
    popd # "pyqt-build-$build_variant"
done

run tar cvJf "pyqt-$VERSION-$BUILD_SPEC.tar.xz" -C "$STAGING/$INSTALL_PREFIX" .
