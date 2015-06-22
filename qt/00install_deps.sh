#!/bin/bash

# For generate_mkspec.py.
pip install click jinja2 pyyaml

QT_DEPS=(
    # Optional Components.
    libicu-devel

    # Extracted from yum-builddep qt
    alsa-lib-devel
    cups-devel
    dbus-devel
    desktop-file-utils
    fontconfig-devel
    freetype-devel
    glib2-devel
    gstreamer-devel
    gstreamer-plugins-base-devel
    gtk2-devel
    krb5-devel
    libICE-devel
    libjpeg-turbo-devel
    libmng-devel
    libpng-devel
    libSM-devel
    libtiff-devel
    libX11-devel
    libXcursor-devel
    libXext-devel
    libXfixes-devel
    libXft-devel
    libXi-devel
    libXinerama-devel
    libXrandr-devel
    libXrender-devel
    libxslt-devel
    libXt-devel
    mesa-libGL-devel
    mesa-libGLU-devel
    mysql-devel
    openssl-devel
    pam-devel
    postgresql-devel
    readline-devel
    sqlite-devel
    unixODBC-devel
    xorg-x11-proto-devel
)

yum install -y "${QT_DEPS[@]}"
