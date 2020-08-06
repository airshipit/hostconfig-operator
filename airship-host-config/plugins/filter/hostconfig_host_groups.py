#!/usr/bin/python3
  
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import itertools
import os

# This plugin calculates the list of list of hosts that need to be executed in 
# sequence as given by the host_groups variable. The AND and OR conditions on the
# host_groups variable is calculated based on the match_host_groups variable
# This returns the list of list of hosts that the ansible should execute the playbook on
# Returns: [[192.168.1.12, 192.168.1.11], [192.168.1.14], [192.168.1.5]]

def host_groups_get_keys(host_groups):
    keys = list()
    values = list()
    for hg in host_groups:
        keys.append(hg['name'])
        values.append(hg['values'])
    print(keys)
    print(values)
    return keys, values

def host_groups_combinations(host_groups):
    keys, values = host_groups_get_keys(host_groups)
    for instance in itertools.product(*values):
        yield dict(zip(keys, instance))

def removeSuccessHosts(hostGroups, hostConfigName):
    filename = '/opt/ansible/data/hostconfig/'+hostConfigName+'/success_hosts'
    print(filename)
    if os.path.isfile(filename):
        hosts = list()
        with open(filename) as f:
            hosts = [line.rstrip() for line in f]
        print(hosts)
        for host in hosts:
            for hostGroup in hostGroups:
                if host in hostGroup:
                    hostGroup.remove(host)
    print(hostGroups)
    return hostGroups

def hostconfig_host_groups(host_groups, groups, hostConfigName, match_host_groups, reexecute):
    host_groups_list = list()
    host_group_list = list()
    if type(host_groups) != list:
        return ''
    if match_host_groups:
        hgs_list = list()
        for host_group in host_groups_combinations(host_groups):
            hg = list()
            for k,v in host_group.items():
                hg.append(k+'_'+v)
            hgs_list.append(hg)
        for hgs in hgs_list:
            host_group = groups[hgs[0]]
            for i in range(1, len(hgs)):
                host_group = list(set(host_group) & set(groups[hgs[i]]))
            host_groups_list.append(host_group)
    else:
        for host_group in host_groups:
            for value in host_group["values"]:
                key = host_group["name"]
                hg = list()
                if key+'_'+value in groups.keys():
                    if not host_group_list:
                        hg = groups[key+'_'+value]
                        host_group_list = hg.copy()
                    else:
                        hg = list((set(groups[key+'_'+value])) - (set(host_group_list) & set(groups[key+'_'+value])))
                        host_group_list.extend(hg)
                    host_groups_list.append(hg)
                else:
                    return "Invalid Host Groups "+key+" and "+value
    if not reexecute:
        return str(removeSuccessHosts(host_groups_list, hostConfigName))
    return str(host_groups_list)


class FilterModule(object):
    ''' HostConfig Host Groups filter plugin for ansible-operator '''

    def filters(self):
        return {
            'hostconfig_host_groups': hostconfig_host_groups
        }
