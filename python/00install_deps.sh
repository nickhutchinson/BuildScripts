#!/bin/bash
deps=(
    # Python deps
    zlib-devel
    sqlite-devel
    db4-devel
    libffi-devel
    openssl-devel
    tk-devel
    expat-devel
)

yum install -y "${deps[@]}"
