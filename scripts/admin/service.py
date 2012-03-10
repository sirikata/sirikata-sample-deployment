'''
A service is one component of a running Sirikata system, e.g. a single
space server, object host, pinto or cseg server. Each service must be
uniquely named and gets isolated storage where it is executed. Usually
a service will be based on a template.
'''

import util
import serviceconfig
import package
import monit

import os.path, subprocess, shutil

# Utilities
def service_path(service, *args):
    '''
    Get path to a service data directory or file.
    '''
    return util.data_path('service', service, *args)

def service_load_config(service):
    """
    Load the configuration for the given service
    """
    util.load_config(serviceconfig, 'service', service)



def service_validate_config(service):
    """
    Validate basic configuration options exist and are valid for the
    given service.
    """
    service_load_config(service)

    # Package
    if not serviceconfig.package:
        print "You must specify a package to provide binaries"
        return 1
    package.package_load_config(serviceconfig.package)
    installdir = package.install_dir(serviceconfig.package)
    bindir = os.path.join(installdir, 'bin')
    if not os.path.exists(installdir) or not os.path.exists(bindir):
        print "Couldn't find installed binaries in package", serviceconfig.package
        return 1

    # Binary
    if not serviceconfig.binary:
        print "You must specify a binary to execute."
        return 1
    binfile = os.path.join(bindir, serviceconfig.binary)
    if not os.path.exists(binfile) or not os.path.isfile(binfile):
        print "Couldn't find binary file", serviceconfig.binary, "in package", serviceconfig.package
        return 1

    # Args - nothing to check, they can be omitted

    return True

# Commands
def command_service_init(*args):
    '''
    admin service init service_name package [template/path/]

    Initialize service directory, optionally copying a template
    service in to get it initialized. You must always specify a
    package, which will be placed in the configuration so the service
    uses binaries from that package.
    '''

    if len(args) < 2:
        print "Must specify at least service name and package."
        return 1

    servname = args[0]
    packname = args[1]
    template = None
    if len(args) > 2:
        template = args[2]
        if not os.path.exists(util.template_path(template)):
            print "Couldn't find template", template
            return 1

    if os.path.exists(service_path(servname)):
        print "Can't create service", servname, ": already exists"
        return 1

    return command_service_reinit(*args)


def command_service_reinit(*args):
    '''
    admin service reinit service_name package [template/path/]

    Reinitialize a service directory, which does what init does but
    will overwrite any existing files. This keeps data in place so
    data can be preserved if the corresponding files haven't changed,
    but the service is forced into a state to match the template
    service.
    '''

    if len(args) < 2:
        print "Must specify at least service name and package."
        return 1

    servname = args[0]
    packname = args[1]
    template = None
    if len(args) > 2:
        template = args[2]
        if not os.path.exists(util.template_path(template)):
            print "Couldn't find template", template
            return 1

    # Copy in template items. To support both init and reinit we:
    # 1. Make sure we have the top level directory
    serv_path = service_path(servname)
    if not os.path.exists(serv_path): os.makedirs(serv_path)
    # 2. Copy all the contents of the template in, excluding the config
    template_dir = util.template_path(template)
    for fi in os.listdir(template_dir):
        if fi != 'config.py':
            template_fi = os.path.join(template_dir, fi)
            serv_fi = os.path.join(serv_path, fi)
            if os.path.isdir(template_fi):
                shutil.copytree(template_fi, serv_fi)
            else:
                shutil.copy(template_fi, serv_fi)

    # Write or overwrite the config file. We need to insert the
    # referenced package and optionally include the template config
    serv_config_py = service_path(servname, 'config.py')
    config_py_file = open(serv_config_py, 'w')
    config_py_file.write("""
package = '%s'

""" % (packname))
    if template:
        template_config = util.template_path(template, 'config.py')
        if os.path.exists(template_config):
            with open(template_config) as f:
                config_py_file.write(f.read())
    config_py_file.close()

    return 0

def get_run_params(servname):
    class Params(object):
        pass

    # Load and validate config
    service_validate_config(servname)

    result = Params()

    result.name = servname
    result.work_dir = service_path(servname)
    result.pidfile = service_path(servname, 'pid')

    result.installdir = package.install_dir(serviceconfig.package)
    result.bindir = os.path.join(result.installdir, 'bin')
    result.binfile = os.path.join(result.bindir, serviceconfig.binary)

    return result

def command_service_rawstart(*args):
    '''
    admin service rawstart service_name

    Start a service running. This is the 'raw' version, which doesn't
    deal with any wrappers like monit. It just starts the daemon
    running. You generally shouldn't need to use this, it's just a
    utility command.
    '''
    if len(args) == 0:
        print 'No service name specified'
        return 1
    params = get_run_params(*args)

    args = []
    if serviceconfig.args:
        args += ['--'] + serviceconfig.args

    cmd = ['start-stop-daemon', '--start', '--quiet', '--background',
           '--chdir', params.work_dir,
           '--pidfile', params.pidfile, '--make-pidfile',
           '--exec', params.binfile]
    cmd += args
    return subprocess.call(cmd, cwd=params.work_dir)

def command_service_rawstop(*args):
    '''
    admin service rawstop service_name

    Stop a currently running service. This is a raw version which
    doesn't handle any wrappers like monit. Generally it should only
    be used internally.
    '''
    if len(args) == 0:
        print 'No service name specified'
        return 1
    params = get_run_params(*args)

    cmd = ['start-stop-daemon', '--stop', '--retry', '10', '--quiet', '--pidfile', params.pidfile]
    return subprocess.call(cmd, cwd=params.work_dir)

def command_service_start(*args):
    '''
    admin service start service_name

    Start a service running
    '''
    if len(args) == 0:
        print 'No service name specified'
        return 1
    params = get_run_params(*args)

    if serviceconfig.monit:
        monit.start_service(args[0])
    else:
        command_service_rawstart(*args)

def command_service_stop(*args):
    '''
    admin service start service_name

    Stop a currently running service.
    '''
    if len(args) == 0:
        print 'No service name specified'
        return 1
    params = get_run_params(*args)

    if serviceconfig.monit:
        monit.stop_service(args[0])
    else:
        command_service_rawstop(*args)


def command_service_debug(*args):
    '''
    admin service debug service_name

    Start a service running under gdb so you can debug it. This
    doesn't add any of the wrappers provided by the normal service
    start/stop commands
    '''
    if len(args) == 0:
        print 'No service name specified'
        return 1
    params = get_run_params(*args)

    cmd = [params.binfile, '--debug']
    if serviceconfig.args:
        cmd += serviceconfig.args
    return subprocess.call(cmd, cwd=params.work_dir)


def command_service_destroy(*args):
    """
    admin service destroy service_name

    Destroy a service, i.e. remove all its contents from the filesystem.
    """

    if len(args) == 0:
        print 'No service name specified'
        return 1
    servname = args[0]
    service_validate_config(servname)

    servdir = service_path(servname)
    if not os.path.exists(servdir):
        return 1

    # Try to stop before we destroy anything, just to be sure we clean
    # up. Worst case, this just fails to do anything
    command_service_stop(*args)

    shutil.rmtree(servdir)
    return 0
