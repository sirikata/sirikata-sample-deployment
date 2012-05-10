'''
This package manages the interface to monit for the set of services
managed by this instance of sirikata-sample-deployment (ideally just
this one per node).  It's preferable to collect all services under a
single monit daemon, with a single config. This module manages getting
services into that config, removing them, and working with the monit
daemon.

To avoid having to deal with databases, we just generate a config file
and use blocks labelled with the corresponding service name in a
comment so we can pick them out for update/removal. You can find the
config file in data/monit.rc
'''

import util
import service
import subprocess, os, stat, time

def _cfgfile():
    return util.data_path('monit.rc')

def _logfile():
    return util.data_path('monit.log')


def monitize_name(n):
    '''Monit service names can't have some characters. This transforms them to ensure names are monit-compatible.'''
    n = n.replace('/', '_')
    return n

def base_config():
    '''Get the basic monit config, which should go at the head of the file'''
    return """
set daemon 15
set logfile %(logfile)s
set httpd port 2812
 use address localhost
 allow localhost
""" % { 'logfile' : _logfile() }


def service_config(name):
    '''Get a config block for the current service (using the current serviceconfig)'''

    params = service.get_run_params(name)
    # We need to handle directories carefully. We need to be careful
    # about two things. First, we need to get the working directory
    # right. For that, we'll make the commands cd into the directory
    # before executing the actual script.
    #
    # We also need to make sure we get the path to the script
    # directory right. For that, we can just use the full directory
    # path to this script since it is colocated with __main__.py.
    #
    # Note that monit seems to make the bizarre decision that it
    # should execute scripts from the root directory, so generally you
    # should be specifying absolute paths for everything or making
    # sure you get yourself into a sane location before doing anything
    # else
    workdir = os.getcwd()
    scriptsdir = os.path.dirname(__file__)
    return """
check process %(monit_name)s
 with pidfile "%(pidfile)s"
 start program = "%(startcommand)s" with timeout 60 seconds
 stop program = "%(stopcommand)s"
 if 4 restarts within 5 cycles then timeout
""" % {
        'name' : params.name,
        'monit_name' : monitize_name(params.name),
        'pidfile' : params.pidfile,
        'startcommand' : "/bin/bash -c 'cd %s; /usr/bin/env python %s service rawstart %s'" % (workdir, scriptsdir, name),
        'stopcommand' : "/bin/bash -c 'cd %s; /usr/bin/env python %s service rawstop %s'" % (workdir, scriptsdir, name),
        }


def load_config():
    '''
    Tries to load the config file. Creates it with a basic config and
    no services if it doesn't exist. Returns a dict of service_name ->
    str config.
    '''
    # Make sure we have something there
    if not os.path.exists(_cfgfile()):
        return { '__base' : base_config() }

    configs = { '__base' : '' }
    with open(_cfgfile(), 'r') as f:
        cur_service_name = '__base'
        for line in f.readlines():
            if line.startswith('\n'):
                continue
            elif line.startswith('### SERVICE '):
                # Remove the prefix and make sure it has an entry
                cur_service_name = line[(len('### SERVICE ')):-1]
                if cur_service_name not in configs:
                    configs[cur_service_name] = ''
            elif line.startswith('### ENDSERVICE'):
                cur_service_name = '__base'
            else:
                # Normal case, just append
                configs[cur_service_name] += line
    return configs

def save_config(configs, do_reload=True):
    '''
    Save a config. The parameters should have the same structure as
    the result of load_config.
    '''
    with open(_cfgfile(), 'w') as f:
        for serv in sorted(configs.keys()):
            if serv != '__base':
                f.write('### SERVICE ' + serv + '\n')
            f.write(configs[serv])
            if serv != '__base':
                f.write('### ENDSERVICE ' + serv + '\n\n\n')
    os.chmod(_cfgfile(), stat.S_IRUSR | stat.S_IWUSR)

    # Force a reload
    if do_reload:
        monit_cmd = ['monit', '-c', _cfgfile(), 'reload']
        subprocess.call(monit_cmd)
        time.sleep(5)

        monit_cmd = ['monit', '-c', _cfgfile(), 'start', 'all']
        subprocess.call(monit_cmd)
        time.sleep(5)


# Commands against monit. These *mostly* shouldn't be exposed directly
# since they are mostly just helpers for starting/stopping services
# that have been placed under monit control. The exception will be
# restarting all services that should be running, e.g. after a
# restart.
def command_monit_start(*args):
    '''Start the monit daemon. You should run this before starting any monit-enabled services.'''

    # Ensure there's a config by loading it and resaving it. Don't
    # reload since there shouldn't be anything running, or if there
    # is, we'll kill it and start from scratch anyway.
    config = load_config()
    save_config(config, do_reload=False)

    # Kill the daemon if it's already running
    command_monit_stop(*args)

    # Start new daemon with new config
    monit_cmd = ['monit', '-c', _cfgfile()]
    subprocess.call(monit_cmd)
    time.sleep(5)

    # Start all services. This case really just covers the reboot
    # case. Otherwise, we shouldn't have to do this. Of course, after
    # reboot you might need to do this more carefully anyway since
    # startup order is possibly important in some cases.
    monit_cmd = ['monit', '-c', _cfgfile(), 'start', 'all']
    time.sleep(5)
    return subprocess.call(monit_cmd)

def command_monit_stop(*args):
    '''Stop the monit daemon.'''
    # Quit current instance
    monit_cmd = ['monit', '-c', _cfgfile(), '-I', 'quit']
    subprocess.call(monit_cmd)
    time.sleep(5)

def start_monit_service(name):
    # There's actually nothing to do here. The save_config() call that
    # you need to do to use this will update monit, and if its not
    # running this wouldn't have done anything anyway. We just have
    # this here so the calls are symmetric.
    pass

def stop_monit_service(name):
    monit_cmd = ['monit', '-c', _cfgfile(), 'stop', monitize_name(name)]
    return subprocess.call(monit_cmd)


# Control of services. Only expose start and stop, but start and stop
# also add and remove entries so that between restarts we don't
# accidentally restart a service we don't need anymore.

def start_service(name):
    config = load_config()

    # We might need to stop an existing service and replace it
    if name in config:
        stop_monit_service(name)
        del config[name]

    # Then put the new config in place and save, then start
    config[name] = service_config(name)
    save_config(config)
    start_monit_service(name)

def stop_service(name):
    config = load_config()
    if name in config:
        # Make sure we stop it first
        stop_monit_service(name)
        # Then clear it out of the config and save
        del config[name]
        save_config(config)
