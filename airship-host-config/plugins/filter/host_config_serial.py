#!/usr/bin/python3

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import json

# Calculates the length of hosts in each groups
# Interested Groups are defined using the host_groups
# Returns a list of integers
def host_config_serial(host_groups, groups):
    serial_list = list()
    if type(host_groups) != list:
        return ''
    for i in host_groups:
        if i in groups.keys():
            serial_list.append(str(len(groups[i])))
    return str(serial_list)


class FilterModule(object):
    ''' HostConfig Serial plugin for ansible-operator '''

    def filters(self):
        return {
            'host_config_serial': host_config_serial
        }
