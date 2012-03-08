
import os

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

def load_config(mod, *args):
    """
    Load the configuration from the given data path,
    e.g. load_config(packageconfig, 'foo', 'bar') loads data_base/foo/bar/config.py
    """
    mod.load_config( data_path(os.path.join(*args), 'config.py') )
