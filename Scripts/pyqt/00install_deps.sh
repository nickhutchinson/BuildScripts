#!/bin/bash

yum install -y epel-release
yum install -y python-pip

# For generate_mkspec.py.
pip install click jinja2 pyyaml

yum install gstreamer gstreamer-plugins-base libICE libSM libXext libpng mesa-libGL-devel
