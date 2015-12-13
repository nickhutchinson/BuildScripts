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
    >&2 printf "+"
    >&2 printf " %q" "$@"
    >&2 printf "\n"
    "$@"
}

DEPS=(
    asciidoc
    curl-devel
    expat-devel
    gettext-devel
    libcurl-devel
    openssl-devel
    pcre-devel
    perl-Error
    perl-ExtUtils-MakeMaker
    subversion-devel
    zlib-devel
)
yum install -y "${DEPS[@]}"

STAGING="$ROOT/staging-git"
mkdir -p "$STAGING"

VERSION=2.6.4

get_url "https://www.kernel.org/pub/software/scm/git/git-$VERSION.tar.xz"
get_url "https://www.kernel.org/pub/software/scm/git/git-manpages-$VERSION.tar.xz"
get_url "https://www.kernel.org/pub/software/scm/git/git-htmldocs-$VERSION.tar.xz"

mkdir -p git-build
pushd git-build

run tar xfv "$ROOT/git-$VERSION.tar.xz" --strip-components=1

run ./configure --prefix=/usr --with-libpcre
run make "-j$(nproc)" install DESTDIR="$STAGING"
popd # "git-build"

pushd "$STAGING"
mkdir -p "usr/share/doc/git-doc"
pushd "usr/share/doc/git-doc"
run tar xfv "$ROOT/git-htmldocs-$VERSION.tar.xz"
run find . -type f -regex ".*(html|txt)" | xargs -r chmod 0644
run find . -type d | xargs -r chmod 0755
popd # git-doc

mkdir -p "usr/share/man"
pushd "usr/share/man"
run tar xfv "$ROOT/git-manpages-$VERSION.tar.xz"
popd # man
popd # $STAGING

fpm_args=(
    -s dir
    -t rpm
    --rpm-compression=xz
    --maintainer 'Nick Hutchinson <nick.hutchinson@thefoundry.co.uk>'
    --depends pcre
    --depends perl-Error
    -n git
    -v "$VERSION"
    --rpm-auto-add-directories
    --replaces perl-Git
    --provides perl-Git
)

run find "$STAGING" -type f | xargs strip --strip-debug || true
run fpm "${fpm_args[@]}" -C "$STAGING" .
