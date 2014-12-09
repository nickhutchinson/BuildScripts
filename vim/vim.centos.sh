#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run() {
    >&2 echo "+ $@"
    "$@"
}

################################################################################
# Build LuaJIT
STAGING_LUAJIT="$ROOT/staging-luajit"
mkdir -p "$STAGING_LUAJIT"
LUAJIT="LuaJIT-2.0.3"
curl -C - -fL -o "$LUAJIT.tar.gz" "http://luajit.org/download/$LUAJIT.tar.gz"

mkdir -p "luajit-build"
pushd "luajit-build"
tar xfv "$ROOT/$LUAJIT.tar.gz" --strip-components=1
perl -pi -e "s|/usr/local|/usr|g" Makefile
make amalg install "DESTDIR=$STAGING_LUAJIT"
popd

# Remove shared libs -- we want to statically link
find "$STAGING_LUAJIT" -name "libluajit-5.1.so*" | xargs rm -v

################################################################################
# Build Vim

# Install deps
yum-builddep -y vim-enhanced
yum install -y             \
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

STAGING_VIM="$ROOT/staging-vim"
mkdir -p "$STAGING_VIM"

VIM="vim7.4.488"
run curl -C - -fL -o "$VIM.tar.gz" "http://ftp.debian.org/debian/pool/main/v/vim/vim_7.4.488.orig.tar.gz"

mkdir -p vim-build
pushd vim-build

run tar xfv "$ROOT/$VIM.tar.gz" --strip-components=1

run env PATH="$STAGING_LUAJIT/usr/bin:$PATH" \
    ./configure                              \
    --with-features=huge                     \
    --enable-multibyte                       \
    --enable-rubyinterp                      \
    --enable-pythoninterp                    \
    --enable-perlinterp                      \
    --enable-luainterp                       \
    --with-luajit                            \
    --with-lua-prefix="$STAGING_LUAJIT/usr"  \
    --enable-gui=gtk2                        \
    --enable-cscope                          \
    --prefix=/usr

run make "-j$(nproc)"                    \
    install                              \
    VIMRUNTIMEDIR="/usr/share/vim/vim74" \
    DESTDIR="$STAGING_VIM"

popd

