#/usr/bin/env python

import sys
import os, os.path
import subprocess, tempfile
import datetime
import shutil
import config

def data_path(depname, *args):
    """
    Get path to a deployment data directory or file. Just wraps
    os.path.join and ensures you have specified a deployment name.
    """
    return os.path.join(os.getcwd(), 'data', depname, *args)

def get_depname(cmd):
    """
    Extract the dependency
    """
    if len(sys.argv) < 3:
        command_help([cmd])
        return -1
    return sys.argv[2]

def command_init():
    """
    admin init deployment_name

    Initialize a new deployment with the given name. This sets up some
    basic directory structures and data. You can edit the configuration
    """
    depname = get_depname('init')
    if depname < 0: return depname

    # Setup build, install, and data directories
    if not os.path.exists(data_path(depname)): os.makedirs(data_path(depname))
    if not os.path.exists(data_path(depname, 'build')): os.makedirs(data_path(depname, 'build'))
    if not os.path.exists(data_path(depname, 'installed')): os.makedirs(data_path(depname, 'installed'))
    if not os.path.exists(data_path(depname, 'data')): os.makedirs(data_path(depname, 'data'))

    # Touch an empty config.py where the user can adjust settings
    config_py_file = open(data_path(depname, 'config.py'), 'w')
    config_py_file.close()

    return 0

def load_config(depname):
    """
    Load the configuration for the given deployment.
    """
    config.load_config( data_path(depname, 'config.py') )

def command_build():
    """
    admin build deployment_name

    Build the given deployment, generating the installed
    version. Unless the deployment is bare, this doesn't do anything
    to update the code or dependencies.
    """

    depname = get_depname('build')
    if depname < 0: return depname
    load_config(depname)

    builddir = data_path(depname, config.build_dir_name)
    depsdir = os.path.join(builddir, 'dependencies')
    buildcmakedir = os.path.join(builddir, 'build', 'cmake')
    installdir = data_path(depname, config.install_dir_name)

    try:
        # If nothing is there yet, do checkout and build dependencies
        if not os.path.exists(data_path(depname, config.build_dir_name, '.git')):
            subprocess.check_call(['git', 'clone', config.repository, data_path(depname, config.build_dir_name)])
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


def command_install():
    """
    admin install deployment_name url

    Install a prebuilt version of Sirikata locally (as opposed to
    building and installing locally.
    """

    depname = get_depname('build')
    if depname < 0: return depname
    load_config(depname)

    if len(sys.argv) < 4:
        print "Must specify a URL to install from"
        return -1
    binary_url = sys.argv[3]

    depdir = data_path(depname)
    installdir = data_path(depname, config.install_dir_name)

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
            print curdir, os.listdir(curdir), subdirs
            assert(len(subdirs) == 1)
            curdir = os.path.join(curdir, subdirs[0])
        # Now swap the directory we found into place
        shutil.rmtree(installdir)
        shutil.move(curdir, installdir)
        # Cleanup
        shutil.rmtree(tempdir)
    except subprocess.CalledProcessError:
        return -1



def command_help(args=None):
    """
    admin help command-name

    Get help about a given command.
    """

    if args is None: args = sys.argv[2:]

    if len(args) == 0:
        print "Usage: admin help command-name"
        return -1

    cmd = args[0]
    cmd_fname = 'command_' + cmd
    if cmd_fname not in globals():
        print "Command not found:", cmd
        return -1

    print globals()[cmd_fname].__doc__

    return 0

def main():
    if len(sys.argv) == 1:
        print "Usage: admin command-name [options]"
        return -1

    cmd = sys.argv[1]
    cmd_fname = 'command_' + cmd
    if cmd_fname not in globals():
        print "Command not found:", cmd
        return -1

    return globals()[cmd_fname]()

if __name__ == "__main__":
    sys.exit(main())
