#!/usr/bin/env python

# This module contains default settings for deployments. You can
# override these in a deployment by redefining these values in your
# deployments config.py.


# Repository to work with
repository = 'git://github.com/sirikata/sirikata.git'

# Directories within
build_dir_name = 'build'
install_dir_name = 'install'
data_dir_name = 'data'

# Dependencies to build
dependencies_targets = ['minimal-depends', 'installed-bullet', 'installed-opencollada', 'installed-v8', 'installed-nvtt', 'installed-libcassandra', 'installed-hiredis']

# Build settings
build_type = 'Debug'
additional_cmake_args = []
additional_make_args = ['-j2']

# This is the only method exported from this module, allowing scripts
# to point the module at other configurations it should load
def load_config(path):
    exec open(path, 'r') in globals()
