#/usr/bin/env python

import sys
import os, os.path
import subprocess, tempfile
import datetime
import shutil
import config

# General utilities
def data_path(*args):
    """
    Get path to a data directory or file. Just wraps
    os.path.join.
    """
    return os.path.join(os.getcwd(), 'data', *args)

def ensure_dir_exists(p):
    '''Ensure a directory exists, creating it if it doesn't'''
    if not os.path.exists(p): os.makedirs(p)

def load_config(*args):
    """
    Load the configuration from the given data path,
    e.g. load_config('foo', 'bar') loads data_base/foo/bar/config.py
    """
    config.load_config( data_path(os.path.join(*args), 'config.py') )


# Package utilities
def package_path(package, *args):
    '''
    Get path to a package data directory or file.
    '''
    return data_path('packages', package, *args)

def package_load_config(package):
    """
    Load the configuration for the given package
    """
    load_config('packages', package)



# Package commands

def command_package_init(*args):
    """
    admin package init package_name

    Initialize a new package of Sirikata. Packages are a build of
    Sirikata you might want to execute multiple services from. This
    command sets up the basic directory structure for a package,
    including a customizable configuration file which you probably
    want to edit after running this command.
    """

    if len(args) == 0:
        print 'No package name specified'
        return -1
    packname = args[0]

    # Setup build, install, and data directories
    ensure_dir_exists(package_path(packname))

    # Touch an empty config.py where the user can adjust settings
    config_py_file = open(package_path(packname, 'config.py'), 'w')
    config_py_file.close()

    return 0

def command_package_build(*args):
    """
    admin build deployment_name

    Build the given deployment, generating the installed
    version. Unless the deployment is bare, this doesn't do anything
    to update the code or dependencies.
    """

    if len(args) == 0:
        print 'No package name specified'
        return -1
    packname = args[0]
    package_load_config(packname)

    builddir = package_path(packname, config.build_dir_name)
    depsdir = os.path.join(builddir, 'dependencies')
    buildcmakedir = os.path.join(builddir, 'build', 'cmake')
    installdir = package_path(packname, config.install_dir_name)

    try:
        # If nothing is there yet, do checkout and build dependencies
        if not os.path.exists(package_path(packname, config.build_dir_name, '.git')):
            subprocess.check_call(['git', 'clone', config.repository, package_path(packname, config.build_dir_name)])
            subprocess.check_call(['make', 'update-dependencies'], cwd=builddir)
            subprocess.check_call(['make'] + config.dependencies_targets, cwd=depsdir)

        # Normal build process
        subprocess.check_call(['./cmake_with_tools.sh',
                               '-DCMAKE_INSTALL_PREFIX='+installdir,
                               '-DCMAKE_BUILD_TYPE='+config.build_type]
                              + config.additional_cmake_args + ['.'],
                              cwd=buildcmakedir)
        subprocess.check_call(['make'] + config.additional_make_args, cwd=buildcmakedir)
        subprocess.check_call(['make', 'install'] + config.additional_make_args, cwd=buildcmakedir)
    except subprocess.CalledProcessError:
        return -1


def command_package_install(*args):
    """
    admin install deployment_name url

    Install a prebuilt version of Sirikata locally (as opposed to
    building and installing locally.
    """

    if len(args) == 0:
        print 'No package name specified'
        return -1
    packname = args[0]
    package_load_config(packname)

    if len(args) < 2:
        print "Must specify a URL to install from"
        return -1
    binary_url = args[1]

    depdir = package_path(packname)
    installdir = package_path(packname, config.install_dir_name)

    tempdir = os.path.join(tempfile.gettempdir(), 'sirikata-deploy-' + str(datetime.datetime.now().time()))
    os.mkdir(tempdir)

    try:
        subprocess.check_call(['curl', '-O', binary_url], cwd=tempdir)
        fname = binary_url.rsplit('/', 1)[1]
        if fname.endswith('tar.gz') or fname.endswith('tgz'):
            subprocess.check_call(['tar', '-xzvf', fname], cwd=tempdir)
        elif fname.endswith('tar.bz2'):
            subprocess.check_call(['tar', '-xjvf', fname], cwd=tempdir)
        elif fname.endswith('zip'):
            subprocess.check_call(['unzip', fname], cwd=tempdir)
        else:
            print "Don't know how to extract file", fname
            return -1

        # Figure out where the actual install is since archives
        # frequently have a layer of extra directories
        curdir = tempdir
        while True:
            subdirs = [x for x in os.listdir(curdir) if os.path.isdir(os.path.join(curdir, x))]
            if 'bin' in subdirs:
                break
            assert(len(subdirs) == 1)
            curdir = os.path.join(curdir, subdirs[0])
        # Now swap the directory we found into place
        if os.path.exists(installdir): shutil.rmtree(installdir)
        shutil.move(curdir, installdir)
        # Cleanup
        shutil.rmtree(tempdir)
    except subprocess.CalledProcessError:
        return -1






# Drivers

def decode_command(*args):
    '''
    Try to decode the command and return a tuple of the command method
    and the remaining arguments. If decoding fails, returns a tuple
    containing None.
    '''
    if len(args) == 0:
        print "Usage: admin command-name [options]"
        return (None, None)

    cmd = args[0]
    cmd_fname = 'command_' + cmd
    if cmd_fname in globals():
        return ( globals()[cmd_fname], args[1:] )

    if len(args) > 1:
        cmd_fname = 'command_' + '_'.join(args[:2])
        if cmd_fname in globals():
            return ( globals()[cmd_fname], args[2:] )

    print "Command not found:", args[0]
    return (None, None)


def command_help(*args):
    """
    admin help command-name

    Get help about a given command.
    """

    if len(args) == 0:
        print "Usage: admin help command-name"
        return -1

    cmd, rest_args = decode_command(*args)
    if cmd is None:
        print "Command not found:", args
        return -1

    print cmd.__doc__

    return 0

def main():
    cmd, rest_args = decode_command(*(sys.argv[1:]))
    if cmd is None: return -1
    return cmd(*rest_args)

if __name__ == "__main__":
    sys.exit(main())
