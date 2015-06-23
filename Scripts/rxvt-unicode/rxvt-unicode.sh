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

# yum builddep rxvt-unicode-256color
DEPS=(
    desktop-file-utils
    fontconfig-devel
    freetype-devel
    glib2-devel
    libX11-devel
    libXft-devel
    libXrender-devel
    libXt-devel
    ncurses
    ncurses-base
    ncurses-devel
    perl-devel
    perl-ExtUtils-Embed
    xorg-x11-proto-devel
)
yum install -y "${DEPS[@]}"

STAGING="$ROOT/staging-rxvt-unicode"
mkdir -p "$STAGING"

PACKAGE_NAME=rxvt-unicode
VERSION=9.21
FILE="rxvt-unicode-${VERSION}.tar.bz2"
URL="http://dist.schmorp.de/rxvt-unicode/$FILE"

get_url "$URL"

mkdir -p rxvt-unicode-build
pushd rxvt-unicode-build

run tar xfv "$ROOT/$FILE" --strip-components=1

run ./configure --prefix=/usr --enable-everything --enable-256-color
run make "-j$(nproc)" install DESTDIR="$STAGING"
popd # "rxvt-unicode-build"

fpm_args=(
    -s dir
    -t rpm
    --rpm-compression=xz
    --maintainer 'Nick Hutchinson <nick.hutchinson@thefoundry.co.uk>'

    -n "$PACKAGE_NAME"
    -v "$VERSION"
    --epoch 1

    --rpm-auto-add-directories
)

run find "$STAGING" -type f | xargs strip --strip-debug || true
run fpm "${fpm_args[@]}" -C "$STAGING" .
