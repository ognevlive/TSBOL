import sys
import os
import configparser

def read(path):
    if not os.path.exists(path):
        return -1

    config = configparser.ConfigParser()
    config.read(path)
    
    dictionary = {}
    for section in config.sections():
        dictionary[section] = {}
        for option in config.options(section):
            dictionary[section][option] = config.get(section, option)

    return dictionary