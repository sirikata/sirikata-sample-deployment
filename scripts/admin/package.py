import util
import packageconfig

import os
import subprocess, tempfile
import datetime
import shutil

# Package utilities
def package_path(package, *args):
    '''
    Get path to a package data directory or file.
    '''
    return util.data_path('packages', package, *args)

def package_load_config(package):
    """
    Load the configuration for the given package
    """
    util.load_config(packageconfig, 'packages', package)

def install_dir(packname):
    return package_path(packname, packageconfig.install_dir_name)

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
        return 1
    packname = args[0]

    # Setup build, install, and data directories
    util.ensure_dir_exists(package_path(packname))

    # Touch an empty config.py where the user can adjust settings
    config_py_file = open(package_path(packname, 'config.py'), 'w')
    config_py_file.close()

    return 0

def command_package_build(*args):
    """
    admin package build deployment_name

    Build the given deployment, generating the installed
    version. Unless the deployment is bare, this doesn't do anything
    to update the code or dependencies.
    """

    if len(args) == 0:
        print 'No package name specified'
        return 1
    packname = args[0]
    package_load_config(packname)

    builddir = package_path(packname, packageconfig.build_dir_name)
    depsdir = os.path.join(builddir, 'dependencies')
    buildcmakedir = os.path.join(builddir, 'build', 'cmake')
    installdir = install_dir(packname)

    try:
        # If nothing is there yet, do checkout and build dependencies
        if not os.path.exists(package_path(packname, packageconfig.build_dir_name, '.git')):
            subprocess.check_call(['git', 'clone', packageconfig.repository, package_path(packname, packageconfig.build_dir_name)])
            subprocess.check_call(['make', 'update-dependencies'], cwd=builddir)
            subprocess.check_call(['make'] + packageconfig.dependencies_targets, cwd=depsdir)

        # Normal build process
        subprocess.check_call(['./cmake_with_tools.sh',
                               '-DCMAKE_INSTALL_PREFIX='+installdir,
                               '-DCMAKE_BUILD_TYPE='+packageconfig.build_type]
                              + packageconfig.additional_cmake_args + ['.'],
                              cwd=buildcmakedir)
        subprocess.check_call(['make'] + packageconfig.additional_make_args, cwd=buildcmakedir)
        subprocess.check_call(['make', 'install'] + packageconfig.additional_make_args, cwd=buildcmakedir)
    except subprocess.CalledProcessError:
        return 1

    return 0

def command_package_install(*args):
    """
    admin package install deployment_name url

    Install a prebuilt version of Sirikata locally (as opposed to
    building and installing locally.
    """

    if len(args) == 0:
        print 'No package name specified'
        return 1
    packname = args[0]
    package_load_config(packname)

    if len(args) < 2:
        print "Must specify a URL to install from"
        return 1
    binary_url = args[1]

    depdir = package_path(packname)
    installdir = package_path(packname, packageconfig.install_dir_name)

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
            return 1

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
        return 1

    return 0

def command_package_destroy(*args):
    """
    admin package destroy package_name

    Destroy a package, i.e. remove all its contents from the filesystem.
    """

    if len(args) == 0:
        print 'No package name specified'
        return 1
    packname = args[0]
    package_load_config(packname)

    packdir = package_path(packname)
    if not os.path.exists(packdir):
        return 1

    shutil.rmtree(packdir)
    return 0
