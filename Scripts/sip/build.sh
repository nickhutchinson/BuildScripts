#!/bin/bash
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/_common.sh"

VERSION=4.15.5
get_url "http://downloads.sourceforge.net/project/pyqt/sip/sip-${VERSION}/sip-${VERSION}.tar.gz"
extract "$ROOT/sip-${VERSION}.tar.gz" "sip-src"

PYTHON_VERSION=2.7.3
PYTHON_VERSION_MAJOR=2.7
PYTHON_ARCHIVE=$ARTEFACTS_DIR/python-${PYTHON_VERSION}-x86_64-centos6.tar.xz
PYTHON_PREFIX=$ROOT/sip-deps/python
run mkdir -p "$PYTHON_PREFIX"

# FIXME: get rid of annoying './' component from archives; replace with archive
# basename.
run tar xfv "$PYTHON_ARCHIVE" -C "$PYTHON_PREFIX" --strip-components=2 \
    ./python-${PYTHON_VERSION}-release

for build_variant in asan+ubsan tsan release; do
    mkdir -p "sip-build-$build_variant"
    pushd "sip-build-$build_variant"
    run rsync -avh "$ROOT/sip-src/" .

    mkspec=linux-g++-$build_variant
    mkspec_opts=(
        "--template=$HERE/mkspec_template.jinja"
        "--config=$HERE/mkspec_config.yaml"
        "--build-variant=$build_variant"
        -o "specs/$mkspec"
    )

    run "$HERE/generate_mkspec.py" "${mkspec_opts[@]}"

    prefix=$INSTALL_PREFIX/sip-$VERSION-$build_variant
    config_args=(
        "--platform=$mkspec"
        "--bindir=$prefix/bin"
        "--destdir=$prefix/lib/python${PYTHON_VERSION_MAJOR}/site-packages"
        "--incdir=$prefix/include"
        "--sipdir=$prefix/share/sip"
    )

    run "$PYTHON_PREFIX/bin/python" "configure.py" "${config_args[@]}"
    run make "-j$(nproc)"
    run env DESTDIR="$STAGING" make install
    popd # "sip-build-$build_variant"
done

run tar cvJf "sip-$VERSION-$BUILD_SPEC.tar.xz" -C "$STAGING/$INSTALL_PREFIX" .
