'''
A template provides all the components and configurations to construct
a complete system. It has templates for each service that needs to be
run. The simplest blank world only requires a single space
server. More complicated templates could provide object hosts that
provide initial content (and permanent hosting) or multiple space
servers and associated services like oseg, cseg, and pinto.

Unlike packages and services, these commands aren't for manipulating
templates. Templates are just collections of files organized into
directories for each service, so they are trivially created and
edited. Instead, these commands help with initializing services from
templates (since there may be many to initialize) and getting the
services running.
'''

import util
import templateconfig
import service
import os, shutil, time

# Template utilities
template_path = util.template_path

def template_load_config(template):
    """
    Load the configuration for the given template
    """
    templateconfig.load_config(template_path(template, 'template.py'))

def template_load_instance_config(prefix):
    """
    Load the configuration for an instance with the given prefix
    """
    templateconfig.load_config(service.service_path(prefix, 'template.py'))

def validate_config():
    if templateconfig.services is None:
        print "You must specify a list of services in template.py"
        return False

    # TODO(ewencp) need to make this work for both templates and instanced templates
    #for s in templateconfig.services:
    #    servpath = util.template_path(template, s.source)
    #    if not os.path.exists(servpath) or not os.path.isdir(servpath):
    #        print "Service '" + s.source + "' doesn't exist within", template
    #        return 1

    return True

def validate_template_config(template):
    '''Load a config directly from a template that hasn't been instantiated and validate it.'''
    template_load_config(template)
    return validate_config()

def validate_instance_config(prefix):
    '''Load an instance of a template's config and validate it.'''
    template_load_instance_config(prefix)
    return validate_config()


def command_template_init(*args):
    '''
    admin template init prefix template_name package

    Instantiate this template into a set of services with a common
    prefix. For example, if the template has services 'space' and
    'oh', a prefix of 'myworld' will result in two services,
    'myworld-space' and 'myworld-oh'.
    '''
    if len(args) < 3:
        print "Must specify at least template name and service prefix"
        return 1

    prefix = args[0]
    template = args[1]
    package = args[2]

    if not validate_template_config(template):
        return 1

    # First sanity check that we don't have any services in the way
    top_servpath = service.service_path(prefix)
    if os.path.exists(top_servpath):
        print "Top-level service directory", top_servpath, "already exists."
        return 1
    svcs = templateconfig.services
    for s in svcs:
        servpath = service.service_path(prefix, s.name)
        if os.path.exists(servpath):
            print "Service directory", os.path.join(prefix, s.name), "already exists."
            return 1

    # Then instantiate each of them
    svcs = templateconfig.services
    for s in svcs:
        servname = os.path.join(prefix, s.name)
        service.command_service_init(*[servname, package, os.path.join(template, s.source)])

    # Copy the template configuration in so we can make sure we keep the same setup
    shutil.copy(template_path(template, 'template.py'), service.service_path(prefix))


def command_template_start(*args):
    '''
    admin template start prefix

    Run all this templates services that have been instantiated with
    the given prefix
    '''
    if len(args) < 1:
        print "Must specify at least template instance prefix"
        return 1

    prefix = args[0]

    if not validate_instance_config(prefix):
        return 1

    svcs = templateconfig.services
    svcs = sorted(svcs, key=lambda s: s.at)
    now = 0
    for idx in range(len(svcs)):
        s = svcs[idx]
        tdiff = s.at - now
        if tdiff > 0:
            time.sleep(tdiff)
        now = s.at
        servname = os.path.join(prefix, s.name)
        service.command_service_start(*[servname])


def command_template_stop(*args):
    '''
    admin template stop prefix

    Stop all this templates services that have been instantiated with
    the given prefix
    '''
    if len(args) < 1:
        print "Must specify at least template instance prefix"
        return 1

    prefix = args[0]

    if not validate_instance_config(prefix):
        return 1

    svcs = templateconfig.services
    svcs = sorted(svcs, key=lambda s: s.at)
    now = svcs[-1].at
    for idx in reversed(range(len(svcs))):
        s = svcs[idx]
        tdiff = now - s.at
        if tdiff > 0:
            time.sleep(tdiff)
        now = s.at
        servname = os.path.join(prefix, s.name)
        service.command_service_stop(*[servname])


def command_template_destroy(*args):
    '''
    admin template start template_name prefix

    Destroy this template instantiated with the given prefix
    '''
    if len(args) < 1:
        print "Must specify at least template instance prefix"
        return 1

    prefix = args[0]

    if not validate_instance_config(prefix):
        return 1

    # Then instantiate each of them
    svcs = templateconfig.services
    for s in svcs:
        servname = os.path.join(prefix, s.name)
        service.command_service_destroy(*[servname])
    # Make sure we get rid of the parent directory since each
    # individual service only deletes its own directory
    shutil.rmtree( service.service_path(prefix) )
