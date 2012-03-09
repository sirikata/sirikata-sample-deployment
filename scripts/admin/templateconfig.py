#!/usr/bin/env python

# This module contains default settings for templates. You can
# override these in a deployment by redefining these values in your
# templates's template.py.

class Service(object):
    def __init__(self, **kwargs):
        '''
        name -- name of the (instantiated) service
        source -- the source service
        at -- the time to start the service
        '''
        for k in kwargs:
            setattr(self, k, kwargs[k])

# Services - The set of services needed by this template. Each service
# should have an instantiated name, a source to initialize it from,
# and a time, in seconds, when it should start.
services = None
# ex:
# services = [
#    Service(name='my-space', source='space', at=0),
#    Service(name='my-world', source='world', at=5)
#    ]

# This is the only method exported from this module, allowing scripts
# to point the module at other configurations it should load
def load_config(path):
    # By setting defaults in here and marking them as global, we
    # guarantee a clean reset if the same process parses a new set of
    # options

    global services
    services = None
    exec open(path, 'r') in globals()
