#!/usr/bin/python3

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import json

# Futher divides the host_config_serial variable into a new list
# so that for each iteration there will be not more than the 
# strategy(int variable) number of hosts executing
def host_config_serial_strategy(strategy, host_groups, groups):
    serial_list = list()
    if type(strategy) != int and type(host_groups) != list:
        return ''
    for i in host_groups:
        if i in groups.keys():
            length = len(groups[i])
            serial_list += int(length/strategy) * [strategy]
            if length%strategy != 0:
                serial_list.append(length%strategy)
    return str(serial_list)


class FilterModule(object):
    ''' HostConfig Serial Startegy plugin for ansible-operator to calucate the serial variable '''

    def filters(self):
        return {
            'host_config_serial_strategy': host_config_serial_strategy
        }
