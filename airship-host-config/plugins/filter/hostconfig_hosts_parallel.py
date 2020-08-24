#!/usr/bin/python3

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

# This plugin futher divides the host_config_serial variable into a new list
# so that for each iteration there will be not more than the
# max_hosts_parallel(int variable) number of hosts executing
# If we have 3 masters and 5 worker and labels sent are masters and workers
# and the max_hosts_parallel is 2
# Returns: [2, 2, 2, 2] if sequential is false
# Returns: [2, 1, 2, 2, 1] if the sequential is true


def hostconfig_max_hosts_parallel(
        max_hosts_parallel, hostconfig_host_groups, sequential=False):
    parallel_list = list()
    if type(max_hosts_parallel) != int and \
            type(hostconfig_host_groups) != list and (sequential) != bool:
        return ''
    if sequential:
        for hg in hostconfig_host_groups:
            length = len(hg)
            parallel_list += (int(length/max_hosts_parallel)
                              * [max_hosts_parallel])
            if length % max_hosts_parallel != 0:
                parallel_list.append(length % max_hosts_parallel)
    else:
        hgs = list()
        for hg in hostconfig_host_groups:
            hgs.extend(hg)
        length = len(hgs)
        parallel_list += int(length/max_hosts_parallel) * [max_hosts_parallel]
        if length % max_hosts_parallel != 0:
            parallel_list.append(length % max_hosts_parallel)
    return str(parallel_list)


class FilterModule(object):
    ''' HostConfig Max Hosts in Parallel plugin for ansible-operator to \
            calucate the ansible serial variable '''

    def filters(self):
        return {
            'hostconfig_max_hosts_parallel': hostconfig_max_hosts_parallel
        }
