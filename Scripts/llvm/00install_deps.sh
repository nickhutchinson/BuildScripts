#!/bin/bash
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$HERE/_common.sh"

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root"
    exit 1
fi

yum install -y curl

if is_ancient_redhat; then
    get_url "https://dl.fedoraproject.org/pub/epel/epel-release-latest-5.noarch.rpm"
    yum install --nogpgcheck -y epel-release-latest-5.noarch.rpm
fi

deps=(
    # Build-essentials
    automake
    bison
    bzip2
    diffutils
    flex
    gcc
    gcc-c++
    make
    patch
    wget

    # GCC
    zlib-devel
    glibc-devel      # RHEL 5
    glibc-devel.i686 # >RHEL 5

    # LLVM
    libxml2-devel
    swig
    libedit-devel

    # unsure if this is required, but it looks like LLVM is searching for it.
    doxygen

    # Python deps
    sqlite-devel
    db4-devel
    openssl-devel
    tk-devel
)

if is_ancient_redhat; then
    get_url "http://mirror.centos.org/centos/5/os/x86_64/CentOS/xz-libs-4.999.9-0.3.beta.20091007git.el5.x86_64.rpm"
    get_url "http://mirror.centos.org/centos/5/os/x86_64/CentOS/xz-4.999.9-0.3.beta.20091007git.el5.x86_64.rpm"

    deps+=(
        xz-libs-4.999.9-0.3.beta.20091007git.el5.x86_64.rpm
        xz-4.999.9-0.3.beta.20091007git.el5.x86_64.rpm
    )
    yum install --nogpgcheck -y "${deps[@]}"
else
    deps+=(
        xz
    )
    yum install -y "${deps[@]}"
fi
