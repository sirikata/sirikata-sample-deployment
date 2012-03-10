#!/usr/bin/env python

# This module contains default settings for packages. You can
# override these in a deployment by redefining these values in your
# package's config.py.

# Package to run from
package = None

# Binary to run
binary = None

# Arguments. These are a simple list, which can become a pain if you
# want a lot of options, especially if they share common prefixes. In
# that case, factor them out into a config file and just specify
# --cfg=foo.cfg here
args = []

# Whether to run under monit
monit = False

# This is the only method exported from this module, allowing scripts
# to point the module at other configurations it should load
def load_config(path):
    # By setting defaults in here and marking them as global, we
    # guarantee a clean reset if the same process parses a new set of
    # options

    global package, binary, args, monit
    package = None
    binary = None
    args = []
    monit = False

    exec open(path, 'r') in globals()
