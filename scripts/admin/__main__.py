#/usr/bin/env python

import sys
import util

# Get commands from other modules
from package import *
from service import *
from template import *
from monit import *

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
