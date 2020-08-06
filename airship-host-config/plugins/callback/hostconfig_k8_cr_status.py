from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = '''
    callback: hostconfig_k8_cr_status
    callback_type: aggregate
    requirements:
      - whitelist in configuration
    short_description: Adds time to play stats
    version_added: "2.0"
    description:
        - This callback just adds total play duration to the play stats.
'''

from ansible.plugins.callback import CallbackBase


class CallbackModule(CallbackBase):
    """
    This callback module tells you how long your plays ran for.
    """
    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'aggregate'
    CALLBACK_NAME = 'hostconfig_k8_cr_status'
    CALLBACK_NEEDS_WHITELIST = True

    def __init__(self):
        super(CallbackModule, self).__init__()

    def v2_playbook_on_play_start(self, play):
        self.vm = play.get_variable_manager()
        self.skip_status_tasks = ["debug", "k8s_status", "local_action", "set_fact", "k8s_info", "lineinfile"]

    def runner_on_failed(self, host, result, ignore_errors=False):
        self.v2_runner_on_failed(result, ignore_errors=False)

    def runner_on_ok(self, host, res):
        self.v2_runner_on_ok(result)

    def v2_runner_on_failed(self, result, ignore_errors=False):
        self.set_host_config_status(result, True)
        return

    def v2_runner_on_ok(self, result):
        hostname = result._host.name
        if result._task_fields["action"] in self.skip_status_tasks:
            return
        self.set_host_config_status(result)
        return

    def set_host_config_status(self, result, failed=False):
        hostname = result._host.name
        task_name = result.task_name
        task_result = result._result
        status = dict()
        hostConfigStatus = dict()
        host_vars = self.vm.get_vars()['hostvars'][hostname]
        k8_hostname = ''
        if 'kubernetes.io/hostname' in host_vars.keys():
            k8_hostname = host_vars['kubernetes.io/hostname']
        else:
            k8_hostname = hostname
        if 'hostConfigStatus' in self.vm.get_vars()['hostvars']['localhost'].keys():
            hostConfigStatus = self.vm.get_vars()['hostvars']['localhost']['hostConfigStatus']
        if k8_hostname not in hostConfigStatus.keys():
            hostConfigStatus[k8_hostname] = dict()
        if task_name in hostConfigStatus[k8_hostname].keys():
            status[task_name] = hostConfigStatus[k8_hostname][task_name]
        status[task_name] = dict()
        if 'stdout' in task_result.keys() and task_result['stdout'] != '':
            status[task_name]['stdout'] = task_result['stdout']
        if 'stderr' in task_result.keys() and task_result['stderr'] != '':
            status[task_name]['stderr'] = task_result['stderr']
        if 'msg' in task_result.keys() and task_result['msg'] != '':
            status['msg'] = task_result['msg'].replace('\n', ' ')
        if 'results' in task_result.keys() and len(task_result['results']) != 0:
            status[task_name]['results'] = list()
            for res in task_result['results']:
                stat = dict()
                if 'stdout' in res.keys() and res['stdout']:
                    stat['stdout'] = res['stdout']
                if 'stderr' in res.keys() and res['stderr']:
                    stat['stderr'] = res['stderr']
                if 'module_stdout' in res.keys() and res['module_stdout']:
                    stat['module_stdout'] = res['module_stdout']
                if 'module_stderr' in res.keys() and res['module_stderr']:
                    stat['module_stderr'] = res['module_stderr']
                if 'msg' in res.keys() and res['msg']:
                    stat['msg'] = res['msg'].replace('\n', ' ')
                if 'item' in res.keys() and res['item']:
                    stat['item'] = res['item']
                if res['failed']:
                    stat['status'] = "Failed"
                else:
                    stat['status'] = "Successful"
                    stat['stderr'] = ""
                    stat['module_stderr'] = ""
                    if "msg" not in stat.keys():
                        stat['msg'] = ""
                status[task_name]['results'].append(stat)
        if failed:
            status[task_name]['status'] = "Failed"
        else:
            status[task_name]['status'] = "Successful"
            # As the k8s_status module is merging the current and previous status, if there are any previous failure messages overriding them https://github.com/fabianvf/ansible-k8s-status-module/blob/master/k8s_status.py#L322
            status[task_name]['stderr'] = ""
            if "msg" not in status[task_name].keys():
                status[task_name]['msg'] = ""
        hostConfigStatus[k8_hostname].update(status)
        self.vm.set_host_variable('localhost', 'hostConfigStatus', hostConfigStatus)
        self._display.display(str(status))
        return
