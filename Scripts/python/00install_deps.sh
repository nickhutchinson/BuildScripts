#!/bin/bash
deps=(
    # Python deps
    bzip2-devel
    db4-devel
    expat-devel
    gdbm-devel
    gmp-devel
    libffi-devel
    ncurses-devel
    openssl-devel
    readline-devel
    sqlite-devel
    tk-devel
    zlib-devel
)

yum install -y "${deps[@]}"
