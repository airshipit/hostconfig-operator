#!/usr/bin/python3

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import json

def serial_strategy(strategy, hosts, groups):
    serial_list = list()
    if type(strategy) != int and type(hosts) != list:
        return ''
    for i in hosts:
        if i in groups.keys():
            length = len(groups[i])
            serial_list += int(length/strategy) * [strategy]
            if length%strategy != 0:
                serial_list.append(length%strategy)
    return str(serial_list)


class FilterModule(object):
    ''' Fake test plugin for ansible-operator '''

    def filters(self):
        return {
            'serial_strategy': serial_strategy
        }
