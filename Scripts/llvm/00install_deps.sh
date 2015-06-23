#!/bin/bash
deps=(
    # GCC
    zlib-devel
    glibc-devel.i686

    # LLVM
    libxml2-devel
    swig
    libedit-devel
    doxygen # not required, but it looks like LLVM is searching for it

    # Python deps
    sqlite-devel
    db4-devel
    libffi-devel
    openssl-devel
    tk-devel
)

yum install -y "${deps[@]}"
