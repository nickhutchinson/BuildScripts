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

################################################################################
# Build LuaJIT
LUAJIT_STAGING_DIR="$ROOT/staging-luajit"
mkdir -p "$LUAJIT_STAGING_DIR"

LUAJIT_TARBALL_NAME="LuaJIT-2.0.4.tar.gz"
get_url "http://luajit.org/download/$LUAJIT_TARBALL_NAME"

mkdir -p "luajit-build"
pushd "luajit-build"
run tar xfv "$ROOT/$LUAJIT_TARBALL_NAME" --strip-components=1
run perl -pi -e "s|/usr/local|/usr|g" Makefile
run make amalg install "DESTDIR=$LUAJIT_STAGING_DIR"
popd

# Remove shared libs -- we want to statically link
run find "$LUAJIT_STAGING_DIR" -name "libluajit-5.1.so*" | xargs -r rm -v

################################################################################
# Build Vim

# Install deps
run sudo yum-builddep -y vim-enhanced
run sudo yum install -y         \
    ruby                   \
    ruby-devel             \
    ctags                  \
    python                 \
    python-devel           \
    perl                   \
    perl-devel             \
    perl-ExtUtils-ParseXS  \
    perl-ExtUtils-CBuilder \
    perl-ExtUtils-Embed

VIM_STAGING_DIR="$ROOT/staging-vim"
mkdir -p "$VIM_STAGING_DIR"

VERSION="7.4.979"
VIM_TARBALL_NAME="v$VERSION.tar.gz"
get_url "https://github.com/vim/vim/archive/$VIM_TARBALL_NAME"

mkdir -p vim-build
pushd vim-build

run tar xfv "$ROOT/$VIM_TARBALL_NAME" --strip-components=1

run env PATH="$LUAJIT_STAGING_DIR/usr/bin:$PATH" \
    ./configure                                  \
    --with-features=huge                         \
    --enable-multibyte                           \
    --enable-rubyinterp                          \
    --enable-pythoninterp                        \
    --enable-perlinterp                          \
    --enable-luainterp                           \
    --with-luajit                                \
    --with-lua-prefix="$LUAJIT_STAGING_DIR/usr"  \
    --enable-gui=gtk2                            \
    --enable-cscope                              \
    --prefix=/usr

run make "-j$(nproc)"                    \
    install                              \
    VIMRUNTIMEDIR="/usr/share/vim/vim74" \
    DESTDIR="$VIM_STAGING_DIR"

popd

fpm_args=(
    -s dir
    -t rpm
    --rpm-compression=xz
    --maintainer 'Nick Hutchinson <nick.hutchinson@thefoundry.co.uk>'

    -n vim
    -v "$VERSION"

    --replaces vim-enhanced
    --replaces vim-common
    --provides vim-common

    # Conflicts with vim-minimal
    -x "*/bin/view"
    -x "*/bin/rview"
    -x "*/bin/ex"
)

run find "$VIM_STAGING_DIR" -type f | xargs strip --strip-debug || true
run fpm "${fpm_args[@]}" -C "$VIM_STAGING_DIR" .
