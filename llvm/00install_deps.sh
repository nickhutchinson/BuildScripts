#!/bin/bash
deps=(
    "https://www.softwarecollections.org/en/scls/rhscl/python27/epel-6-x86_64/download/rhscl-python27-epel-6-x86_64.noarch.rpm"
    scl-utils
    zlib-devel
    libxml2-devel
    python27
)

yum install "${deps[@]}"
