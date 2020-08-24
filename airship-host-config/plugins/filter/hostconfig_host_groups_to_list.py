#!/usr/bin/python3

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

# Converts the list of list of hosts to only a list of hosts
# that is accepted by the ansible playbook for execution
# Returns: [192.168.1.12, 192.168.1.11, 192.168.1.14, 192.168.1.5]


def hostconfig_host_groups_to_list(hostconfig_host_groups):
    host_groups_list = list()
    if type(hostconfig_host_groups) != list:
        return ''
    for hg in hostconfig_host_groups:
        host_groups_list.extend(hg)
    return str(host_groups_list)


class FilterModule(object):
    ''' Plugin to convert list of list to list of \
            strings for ansible-operator '''

    def filters(self):
        return {
            'hostconfig_host_groups_to_list': hostconfig_host_groups_to_list
        }
