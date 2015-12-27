#!/bin/bash
set -euo pipefail

ROOT="$(pwd)"

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

sudo() {
    if [[ $EUID -eq 0 ]]; then
        "$@"
    else
        command sudo "$@"
    fi
}

# Install deps
run sudo yum install -y cmake flex bison

GLSLANG_STAGING_DIR="$ROOT/staging-glslang"
mkdir -p "$GLSLANG_STAGING_DIR"

VERSION="3.0"
GLSLANG_TARBALL_NAME="$VERSION.tar.gz"
get_url "https://github.com/KhronosGroup/glslang/archive/$GLSLANG_TARBALL_NAME"

mkdir -p glslang-build
pushd glslang-build

run tar xfv "$ROOT/$GLSLANG_TARBALL_NAME" --strip-components=1

# Fix borked CMAKE_INSTALL_PREFIX
sed -i 's/^set(CMAKE_INSTALL_PREFIX.*$//g' CMakeLists.txt

cmake . -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release
env DESTDIR=$GLSLANG_STAGING_DIR cmake \
    --build .                          \
    --target install                   \
    --                                 \
    -j$(getconf _NPROCESSORS_ONLN)

popd

fpm_args=(
    -s dir
    -t rpm
    --rpm-compression=xz
    --maintainer 'Nick Hutchinson <nick.hutchinson@thefoundry.co.uk>'

    -n glslang
    -v "$VERSION"
)

run fpm "${fpm_args[@]}" -C "$GLSLANG_STAGING_DIR" .
