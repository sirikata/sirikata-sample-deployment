#!/usr/bin/env python

# This module contains default settings for packages. You can
# override these in a deployment by redefining these values in your
# package's config.py.


# This is the only method exported from this module, allowing scripts
# to point the module at other configurations it should load
def load_config(path):
    # By setting defaults in here and marking them as global, we
    # guarantee a clean reset if the same process parses a new set of
    # options

    # Repository to work with
    global repository
    repository = 'git://github.com/sirikata/sirikata.git'

    # Directories within
    global build_dir_name, install_dir_name, data_dir_name
    build_dir_name = 'build'
    install_dir_name = 'install'
    data_dir_name = 'data'

    # Dependencies to build
    global dependencies_targets
    dependencies_targets = ['minimal-depends', 'installed-bullet', 'installed-opencollada', 'installed-v8', 'installed-nvtt', 'installed-libcassandra', 'installed-hiredis']

    # Branch/version settings
    global version
    # version should be a valid 'tree-ish' reference for git, e.g. a
    # local branch ('master'), remote branch ('origin/master'), tag
    # ('v0.0.1'), git commit ID ('a74568ab'), etc.
    version = 'origin/master'

    # Build settings
    global build_type, additional_cmake_args, additional_make_args
    build_type = 'Debug'
    additional_cmake_args = []
    additional_make_args = ['-j2']

    import os.path
    if not os.path.exists(path):
        return False
    exec open(path, 'r') in globals()
    return True
