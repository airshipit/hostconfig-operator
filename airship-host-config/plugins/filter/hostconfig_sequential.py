#!/usr/bin/python3

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

# Calculates the length of hosts in each groups
# Interested Groups are defined using the host_groups
# Returns a list of integers [2, 1, 3] based on the host_groups variables


def hostconfig_sequential(hostconfig_host_groups, groups):
    seq_list = list()
    if type(hostconfig_host_groups) != list:
        return ''
    for host_group in hostconfig_host_groups:
        if len(host_group) != 0:
            seq_list.append(len(host_group))
    return str(seq_list)


class FilterModule(object):
    ''' HostConfig Sequential plugin for ansible-operator '''

    def filters(self):
        return {
            'hostconfig_sequential': hostconfig_sequential
        }
