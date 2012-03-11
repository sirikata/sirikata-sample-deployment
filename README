About
=====

This is an example of a deployment of Sirikata. The scripts in this
repository help you setup, build, and run various Sirikata services as
well as keep them up to date.

All contents of this repository are available under the BSD
license. See the LICENSE file for details.

How to Use
==========

There's only one driver script to manage deployments,
scripts/admin. It manages three components: packages, services, and
templates.

Packages -- a build of Sirikata containing binaries you'll use.

Services -- an instance of a binary which you need to build your
            system, for example one space server or object host. A
            simple deployment could be made up of the services
            'myworld-space' and 'myworld-objects'.

Templates -- descriptions of a set of services which let you.


Packages
========

To get running, you'll first need to setup a package. First initialize
the package:

    python scripts/admin package init my_package

This doesn't do much, just setting up some space under a data/
directory and placing an empty config.py which you can edit to adjust
the default settings. See scripts/admin/packageconfig.py for
details. By default it's setup to build from the git repository with a
reasonable directory layout. Now you can build the package, which will
build and install sirikata within data/packages/my_package

    python scripts/admin package build my_package

When it completes you should see that the source code checkout is in
data/packages/my_package/build/ and the compiled, installed version is
in data/packages/my_package/install/. If you need to in the future,
you can modify the code and run build and install commands manually or
through the admin script to test new versions of code.

You can also use pre-built binary packages:

    python scripts/admin package install my_package http://myhost.com/path/to/sirikata.tar.gz


Templates
=========

Most deployments require multiple services, and templates are easier
than managing those directly, so we'll talk about them first. You can
see an example template configuration in templates/melville. Each
template has a top-level template.py which adjusts defaults
configuration options for this template. See
scripts/admin/templateconfig.py for options.

Then, each subdirectory describes a service template. Note that these
do not necessarily map to instantiated services because each might be
instantiated multiple times. For example, you may need two space
servers using the same configuration and one object host. You only
need one service template for the space servers.

Each service template contains a config.py to adjust default settings
need one service template for the space servers (see serviceconfig.py
for defaults) as well as all data needed to run the service. The
melville template's space only contains space.cfg (an easier way to
adjust commandline settings than putting them all in one list in
config.py). The world template, however, contains a scene file and a
script for an object in the scene in addition to a configuration file.

To use the template, we instantiate a copy of it with a prefix to
guarantee unique names:

    python scripts/admin template init mymelville melville my_package

All the template commands are immediately followed by the prefix,
mymelville in this case, for consistency. So the previous command said
to instantiate the template 'melville' with the prefix 'mymelville'
and use the package 'my_package' as the source of binaries. You should
now see the services mymelville-space and mymelville-world under
data/services/.

Now to actually run the services:

    python scripts/admin template start mymelville

This may take a few moments as the template.py specifies an ordering
and timing for services to start up so you can ensure, for example,
that the space server is running before the object host
starts. Similarly, shutdown the services with

    python scripts/admin template stop mymelville

If you want to completely remove the configuration and data associated
with the instantiated template, use:

    python scripts/admin template destroy mymelville

All the directories that had been created under data/services/ for
this template should now be deleted.


Services
========

If you are creating your own template or debugging a service, you may
need to control them directly. Since templates just control
collections of services, many of the commands look similar:

    python scripts/admin service init service_name package [template/path/]
    python scripts/admin service start service_name
    python scripts/admin service stop service_name
    python scripts/admin service destroy service_name

On command that doesn't apply to templates is for debugging:

    python scripts/admin service debug service_name

This works similarly to the start command but adds a debug flag so you
will be dropped in a gdb prompt with all the command line flags and
working directory setup properly.


Keeping Services Running
========================

You can run services under monit to ensure the recover from crashes or
failures. Simply add monit = True to the service configuration. The
service and template commands for starting and stopping will place the
processes under monit's control if they find that flag enabled.

You can bypass monit when debugging services using the rawstart and
rawstop commands, which always execute the final command that
starts/stops the service:

    python scripts/admin service rawstart service_name
    python scripts/admin service rawstop service_name

This is useful if you want to debug the service without having to edit
the configuration files.


Getting Help
============

If you need details on any command, use the help command, e.g.:

   python scripts/admin help package install
