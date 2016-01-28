#!/bin/bash

yum install -y epel-release rsync
yum install -y python-pip

# For generate_mkspec.py.
pip install click jinja2 pyyaml
