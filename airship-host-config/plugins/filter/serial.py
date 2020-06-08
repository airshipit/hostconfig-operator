#!/usr/bin/python3

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import json

def serial(hosts, groups):
    serial_list = list()
    if type(hosts) != list:
        return ''
    for i in hosts:
        if i in groups.keys():
            serial_list.append(str(len(groups[i])))
    return str(serial_list)


class FilterModule(object):
    ''' Fake test plugin for ansible-operator '''

    def filters(self):
        return {
            'serial': serial
        }
