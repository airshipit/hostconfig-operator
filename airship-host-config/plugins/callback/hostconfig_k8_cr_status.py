from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import ast
import itertools
import os
import re

from ansible.plugins.callback import CallbackBase
from datetime import datetime, timedelta
from kubernetes import client, config
from kubernetes.client.rest import ApiException

DOCUMENTATION = '''
    callback: hostconfig_k8_cr_status
    callback_type: aggregate
    requirements:
      - whitelist in configuration
    short_description: Adds status field to CR object
    version_added: "1.0"
    description:
        - This callback module update the status field in the
          HostConfig CR object with each task status.
'''


class CallbackModule(CallbackBase):
    """
    This callback module updates the status field in the
    HostConfig CR object with each task status.
    """
    CALLBACK_VERSION = 1.0
    CALLBACK_TYPE = 'aggregate'
    CALLBACK_NAME = 'hostconfig_k8_cr_status'
    CALLBACK_NEEDS_WHITELIST = True

    # Initailize the kubernetes api object and class variables
    def __init__(self):
        super(CallbackModule, self).__init__()
        config.load_incluster_config()
        self.custom_api_instance = client.CustomObjectsApi()
        self.api_instance = client.CoreV1Api()
        self.host_config_status = dict()
        self.ansible_summary = dict()
        self.start_time = datetime.utcnow()
        # Defines which tasks status to skip in the CR object status
        self.skip_status_tasks = [
                "debug", "k8s_status",
                "local_action", "set_fact", "k8s_info",
                "lineinfile", "include_role", "file", "fail"
                ]

    # Intializing the variable manager and host variables
    # Also initializes with the CR object name and namespace
    def v2_playbook_on_play_start(self, play):
        self.vm = play.get_variable_manager()
        self.host_vars = self.vm.get_vars()['hostvars']
        self.hostConfigName = self.host_vars['localhost']['meta']['name']
        self.namespace = self.host_vars['localhost']['meta']['namespace']

    # This function is triggered when a certain task fails with
    # unreachable state
    def runner_on_unreachable(self, host, result):
        self.v2_runner_on_unreachable(result)

    # This function is triggered when a certain task fails with
    # failed state
    def runner_on_failed(self, host, result, ignore_errors=False):
        self.v2_runner_on_failed(result, ignore_errors=False)

    # This function is triggered when a certain task fails with
    # ok state
    def runner_on_ok(self, host, res):
        self.v2_runner_on_ok(result)

    # This function is triggered when a certain task fails with
    # unreachable state in ansible v2 version
    def v2_runner_on_unreachable(self, result):
        self.set_host_config_status(result, False, True)
        return

    # This function is triggered when a certain task fails with
    # failed state in ansible v2 version
    def v2_runner_on_failed(self, result, ignore_errors=False):
        if result._task_fields["action"] == "fail":
            return
        self.set_host_config_status(result, True, False)
        return

    # This function is triggered when a certain task fails with
    # ok state in ansible v2 version
    def v2_runner_on_ok(self, result):
        hostname = result._host.name
        if result._task_fields["action"] in self.skip_status_tasks:
            # Even if the task is set skip if the
            # "set_cr_status" task variable is defined
            # then the task status will be updated in the CR object.
            if "vars" in result._task_fields.keys() and \
                    "set_cr_status" in \
                    result._task_fields["vars"].keys() and \
                    result._task_fields["vars"]["set_cr_status"]:
                self.set_host_config_status(result)
                return
            return
        self.set_host_config_status(result)
        return

    # Builds the hostConfigStatus object, which is used to update the CR
    # The hostConfigStatus is updated based on the task status
    def set_host_config_status(self, result, failed=False, unreachable=False):
        hostname = result._host.name
        task_name = result.task_name
        task_result = result._result
        status = dict()
        host_vars = self.host_vars[hostname]
        k8_hostname = ''
        if 'kubernetes.io/hostname' in host_vars.keys():
            k8_hostname = host_vars['kubernetes.io/hostname']
        else:
            k8_hostname = hostname
        if k8_hostname not in self.host_config_status.keys():
            self.host_config_status[k8_hostname] = dict()
        if task_name in self.host_config_status[k8_hostname].keys():
            status[task_name] = host_config_status[k8_hostname][task_name]
        status[task_name] = dict()
        check_keys = ["stdout", "stderr", "msg"]
        for key in check_keys:
            if key in task_result.keys() and task_result[key] != "":
                status[task_name][key] = task_result[key]
        # If the task executes in for loop; collecting
        # the results of each iteration
        if 'results' in task_result.keys() and \
                len(task_result['results']) != 0:
            status[task_name]['results'] = list()
            check_keys_res = [
                    "stdout", "stderr", "msg",
                    "module_stdout", "module_stderr", "item"
                    ]
            for res in task_result['results']:
                stat = dict()
                for key in check_keys_res:
                    if key in res.keys() and res[key]:
                        stat[key] = res[key]
                if 'failed' in res.keys() and res['failed']:
                    stat['status'] = "Failed"
                elif 'unreachable' in res.keys() and res['unreachable']:
                    stat['status'] = "Unreachable"
                else:
                    stat['status'] = "Successful"
                if "vars" in result._task_fields.keys() and \
                        "cr_status_vars" in \
                        result._task_fields["vars"].keys():
                    for var in result._task_fields["vars"]["cr_status_vars"]:
                        if var in res.keys():
                            stat[var] = res[var]
                        if "ansible_facts" in res.keys() and \
                                var in res["ansible_facts"].keys():
                            stat[var] = res["ansible_facts"][var]
                status[task_name]['results'].append(stat)
        if failed:
            status[task_name]['status'] = "Failed"
        elif unreachable:
            status[task_name]['status'] = "Unreachable"
        else:
            status[task_name]['status'] = "Successful"
        if "vars" in result._task_fields.keys() and \
                "cr_status_vars" in result._task_fields["vars"].keys():
            for var in result._task_fields["vars"]["cr_status_vars"]:
                if var in task_result.keys():
                    status[var] = task_result[var]
                if "ansible_facts" in task_result.keys() and \
                        var in task_result["ansible_facts"].keys():
                    status[var] = task_result["ansible_facts"][var]
        self.host_config_status[k8_hostname].update(status)
        self._display.display(str(status))
        return

    # Determines the iterations completed and further updates the CR object
    # not to schedule further itertations if the reconcile-iterations or
    # reconcile-interval is met
    def update_reconcile_status(self):
        cr_obj = self.get_host_config_cr()
        annotations = self.host_vars['localhost']\
                ['_hostconfig_airshipit_org_hostconfig']\
                ['metadata']['annotations']
        reconcile_status = dict()
        if "ansible.operator-sdk/reconcile-period" in annotations.keys():
            iterations = 0
            pre_iter = None
            if 'reconcileStatus' in cr_obj['status'].keys() and \
                    'completed_iterations' in \
                    cr_obj['status']['reconcileStatus'].keys():
                pre_iter = cr_obj['status']['reconcileStatus']\
                        ['completed_iterations']
            # Checks if the reconcile-interval or period is specified
            if "ansible.operator-sdk/reconcile-interval" in annotations.keys():
                # Calculates the iterations based on the reconcile-interval
                # This executes for the very first iteration only
                if pre_iter is None:
                    interval = annotations["ansible.operator-sdk/reconcile-interval"]
                    period = annotations["ansible.operator-sdk/reconcile-period"]
                    iterations = self.get_iterations_from_interval(
                            interval, period)
                    reconcile_status['total_iterations'] = iterations
                elif 'total_iterations' in \
                        cr_obj['status']['reconcileStatus'].keys():
                    iterations = cr_obj['status']['reconcileStatus']\
                            ['total_iterations']
                else:
                    reconcile_status['msg'] = "Unable to retrieve "+\
                            "total iterations to be executed."
                    return reconcile_status
                if isinstance(iterations, str) \
                        and "greater than or equal to" in iterations:
                    reconcile_status['msg'] = iterations
                    return reconcile_status
                elif isinstance(iterations, str) and \
                        "format not specified" in iterations:
                    reconcile_status['msg'] = iterations
                    return reconcile_status
            elif "ansible.operator-sdk/reconcile-iterations" \
                    in annotations.keys():
                iterations = annotations["ansible.operator-sdk/reconcile-iterations"]
            else:
                reconcile_status['msg'] = "Reconcile iterations or interval "+\
                        "not specified. Running simple reconcile."
                return reconcile_status
            if int(iterations) <= 1:
                reconcile_status['msg'] = "Reconcile iterations or interval "+\
                        "should have iterations more than 1. "+\
                        "Running simple reconcile."
                return reconcile_status
            # If any host fails execution the iteration is not counted
            if self.check_failed_hosts():
                if pre_iter is not None:
                    reconcile_status['completed_iterations'] = pre_iter
                reconcile_status['total_iterations'] = iterations
                reconcile_status['msg'] = "One or More Hosts Failed, "+\
                        "so not considering reconcile."
                return reconcile_status
            if pre_iter is None:
                pre_iter = 0
            current_iter = int(pre_iter)+1
            reconcile_status['total_iterations'] = iterations
            reconcile_status['completed_iterations'] = current_iter
            if int(current_iter) == int(iterations)-1:
                cr_obj["metadata"]["annotations"]\
                        ["ansible.operator-sdk/reconcile-period"] = "0"
                self.custom_api_instance.patch_namespaced_custom_object(
                          group="hostconfig.airshipit.org",
                          version="v1alpha1",
                          plural="hostconfigs",
                          name=self.hostConfigName,
                          namespace=self.namespace,
                          body=cr_obj)
                reconcile_status['msg'] = "Running reconcile based "+\
                        "on reconcile-period. Updated the CR to stop "+\
                        "running reconcile again."
                return reconcile_status
            elif int(current_iter) == int(iterations):
                del reconcile_status['total_iterations']
                del reconcile_status['completed_iterations']
                reconcile_status['msg'] = "Running reconcile completed. "+\
                        "Total iterations completed are "+str(current_iter)
                return reconcile_status
            reconcile_status['msg'] = "Running reconcile based on "+\
                                        "reconcile-period."
        else:
            reconcile_status['msg'] = "No reconcile annotations specified."
        return reconcile_status

    def check_failed_hosts(self):
        if len(self.ansible_summary["failures"].keys()) > 0 or \
                len(self.ansible_summary["unreachable"].keys()) > 0 or \
                len(self.ansible_summary["rescued"].keys()) > 0:
            return True
        return False

    # Determines the reconcile iteration from the reconcile-interval specified
    def get_iterations_from_interval(self, interval, period):
        endsubstring = ['h', 'm', 's', 'ms', 'us', 'ns']
        try:
            if not interval.endswith(tuple(endsubstring)) or \
                    not period.endswith(tuple(endsubstring)):
                return "Reconcile parameters format not \
                        specified appropriately!!"
            regex = re.compile(r'((?P<hours>\d+?)h)?((?P<minutes>\d+?)m)?((?P<seconds>\d+?)s)?((?P<millisecond>\d+?)ms)?((?P<microsecond>\d+?)us)?((?P<nanosecond>\d+?)ns)?')
            interval_re = regex.match(interval)
            period_re = regex.match(period)
            period_dict = dict()
            interval_dict = dict()
            for key, value in period_re.groupdict().items():
                if value:
                    period_dict[key] = int(value)
            for key, value in interval_re.groupdict().items():
                if value:
                    interval_dict[key] = int(value)
            inter = timedelta(**interval_dict)
            peri = timedelta(**period_dict)
            if inter.seconds >= peri.seconds:
                return int(inter/peri)
            else:
                return "The reconcile-interval should be greater than or "+\
                        "equal to reconcile-period!!"
        except Exception as e:
            return "Reconcile parameters format not specified appropriately!!"

    # Calculates the minutes, days and seconds from the execution time
    def days_hours_minutes_seconds(self, runtime):
        minutes = (runtime.seconds // 60) % 60
        r_seconds = runtime.seconds % 60
        return runtime.days, runtime.seconds // 3600, minutes, r_seconds

    # Computes the execution time taken for the playbook to complete
    def execution_time(self, end_time):
        runtime = end_time - self.start_time
        return "Playbook run took %s days, %s hours, %s minutes, %s seconds" % (self.days_hours_minutes_seconds(runtime))

    # Triggered when the playbook execution is completed
    def v2_playbook_on_stats(self, stats):
        self.playbook_on_stats(stats)
        return

    # Triggered when the playbook execution is completed
    # This function updates the CR object with the tasks
    # status and reconcile status
    def playbook_on_stats(self, stats):
        end_time = datetime.utcnow()
        summary_fields = [
                "ok", "failures", "dark", "ignored",
                "rescued", "skipped", "changed"
                ]
        for field in summary_fields:
            stat = stats.__dict__[field]
            status = dict()
            if 'localhost' in stat.keys():
                del stat['localhost']
            for key, value in stat.items():
                if 'kubernetes.io/hostname' in self.host_vars[key].keys():
                    status[self.host_vars[key]['kubernetes.io/hostname']] = \
                            value
                else:
                    status[key] = value
            if field == "dark":
                self.ansible_summary["unreachable"] = status
            else:
                self.ansible_summary[field] = status
        # Gets the reconcile status for the current execution
        reconcile_status = self.update_reconcile_status()
        cr_status = dict()
        self.ansible_summary["completion_timestamp"] = end_time
        self.ansible_summary["execution_time"] = self.execution_time(end_time)
        cr_status['ansibleSummary'] = self.ansible_summary
        cr_obj = self.get_host_config_cr()
        # If the current status has not executed on some hosts
        # updates those details from the with previous iterations status
        if 'hostConfigStatus' in cr_obj['status'].keys():
            status = cr_obj['status']['hostConfigStatus']
            for key, value in status.items():
                if key not in self.host_config_status and key != "localhost":
                    self.host_config_status[key] = value
        cr_obj['status']['hostConfigStatus'] = self.host_config_status
        cr_status['reconcileStatus'] = reconcile_status
        cr_obj['status'].update(cr_status)
        self._display.display("Updating CR Status with below object!!")
        self._display.display(str(cr_status))
        resp = self.custom_api_instance.\
            replace_namespaced_custom_object_status(
                        group="hostconfig.airshipit.org",
                        version="v1alpha1",
                        plural="hostconfigs",
                        name=self.hostConfigName,
                        namespace=self.namespace,
                        body=cr_obj)
        self._display.display("Response from KubeAPI server after "+\
                "sending status update request")
        self._display.display(str(resp))
        return

    # Returns the HostConfig CR object
    # based on the CR object name and namespace
    def get_host_config_cr(self):
        return self.custom_api_instance.\
                get_namespaced_custom_object(
                        group="hostconfig.airshipit.org",
                        version="v1alpha1",
                        namespace=self.namespace,
                        plural="hostconfigs",
                        name=self.hostConfigName)
