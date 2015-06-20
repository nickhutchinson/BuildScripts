#!/bin/bash

# generate_mkspec.py
pip install click jinja2 pyyaml

yum install -y          \
    openssl-devel       \
    mesa-libGL-devel    \
    mesa-libGLU-devel   \
    libXrender-devel    \
    gtk2-devel          \
    libicu-devel        \
    cups-devel          \
    libICE-devel        \
    libSM-devel         \
    libXt-devel         \
    libjpeg-turbo-devel \
    libmng              \
    dbus-devel

# Are these really necessary? Gstreamer/Alsa pull in another 50 dependent
# packages. Ah well.
yum install -y \
    gstreamer-devel gstreamer-plugins-base-devel alsa-lib-devel \
    phonon-backend-gstreamer  
