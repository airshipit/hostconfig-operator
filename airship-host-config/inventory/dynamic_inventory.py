#!/usr/bin/env python3

# Python code to build Inventory dynamically based on the kubernetes nodes
# present in the cluster and labels and annotations associated
# with the kubernetes nodes.

import argparse
import base64
import json
import os
import kubernetes.client

from kubernetes.client.rest import ApiException

interested_labels_annotations = [
        "beta.kubernetes.io/arch", "beta.kubernetes.io/os",
        "kubernetes.io/arch", "kubernetes.io/hostname", "kubernetes.io/os",
        "kubernetes.io/role", "topology.kubernetes.io/region",
        "topology.kubernetes.io/zone", "projectcalico.org/IPv4Address",
        "projectcalico.org/IPv4IPIPTunnelAddr", "Kernel Version", "OS Image",
        "Operating System", "Container Runtime Version",
        "Kubelet Version", "Operating System"
        ]


class KubeInventory(object):

    def __init__(self):
        self.inventory = {}
        self.read_cli_args()

        self.api_instance = kubernetes.client.CoreV1Api(
                kubernetes.config.load_incluster_config())
        if self.args.list:
            self.kube_inventory()
        elif self.args.host:
            # Not implemented, since we return _meta info `--list`.
            self.inventory = self.empty_inventory()
        # If no groups or vars are present, return an empty inventory.
        else:
            self.inventory = self.empty_inventory()

        print(json.dumps(self.inventory, sort_keys=True, indent=4))

    # Kube driven inventory
    def kube_inventory(self):
        self.inventory = {
                "group": {"hosts": [], "vars": {}},
                "_meta": {"hostvars": {}}
                }
        self.get_nodes()

    # Sets the ssh username and password using
    # the secret name given in the label
    def _set_ssh_keys(self, labels, node_internalip, node_name):
        namespace = ""
        if "SECRET_NAMESPACE" in os.environ:
            namespace = os.environ.get("SECRET_NAMESPACE")
        else:
            namespace = "default"
        if "secret" in labels.keys():
            try:
                secret_value = self.api_instance.read_namespaced_secret(
                        labels["secret"], namespace)
            except ApiException as e:
                return False
            if "username" in secret_value.data.keys():
                username = (base64.b64decode(
                    secret_value.data['username'])).decode("utf-8")
                self.inventory["_meta"]["hostvars"]\
                        [node_internalip]["ansible_ssh_user"] = username
            elif "USER" in os.environ:
                self.inventory["_meta"]["hostvars"][node_internalip]\
                        ["ansible_ssh_user"] = os.environ.get("USER")
            else:
                self.inventory["_meta"]["hostvars"]\
                        [node_internalip]["ansible_ssh_user"] = 'kubernetes'
            if "password" in secret_value.data.keys():
                password = (base64.b64decode(
                    secret_value.data['password'])).decode("utf-8")
                self.inventory["_meta"]["hostvars"]\
                        [node_internalip]["ansible_ssh_pass"] = password
            elif "ssh_private_key" in secret_value.data.keys():
                private_key = (base64.b64decode(
                    secret_value.data['ssh_private_key'])).decode("utf-8")
                fileName = "/opt/ansible/.ssh/"+node_name
                with open(os.open(
                        fileName, os.O_CREAT | os.O_WRONLY, 0o644), 'w') as f:
                    f.write(private_key)
                    f.close()
                os.chmod(fileName, 0o600)
                self.inventory["_meta"]["hostvars"][node_internalip][
                    "ansible_ssh_private_key_file"] = fileName
            elif "PASS" in os.environ:
                self.inventory["_meta"]["hostvars"]\
                        [node_internalip]["ansible_ssh_pass"] = os.environ.get("PASS")
            else:
                self.inventory["_meta"]["hostvars"]\
                        [node_internalip]["ansible_ssh_pass"] = 'kubernetes'
        else:
            return False
        return True

    # Sets default username and password from environment variables or
    # some default username/password
    def _set_default_ssh_keys(self, node_internalip):
        if "USER" in os.environ:
            self.inventory["_meta"]["hostvars"]\
                    [node_internalip]["ansible_ssh_user"] = os.environ.get("USER")
        else:
            self.inventory["_meta"]["hostvars"]\
                    [node_internalip]["ansible_ssh_user"] = 'kubernetes'
        if "PASS" in os.environ:
            self.inventory["_meta"]["hostvars"]\
                    [node_internalip]["ansible_ssh_pass"] = os.environ.get("PASS")
        else:
            self.inventory["_meta"]["hostvars"]\
                    [node_internalip]["ansible_ssh_pass"] = 'kubernetes'
        return

    # Gets the Kubernetes nodes labels and annotations and build the inventory
    # Also groups the kubernetes nodes based on the labels and annotations
    def get_nodes(self):
        try:
            nodes = self.api_instance.list_node().to_dict()[
                "items"
            ]
        except ApiException as e:
            return False

        for node in nodes:
            addresses = node["status"]["addresses"]
            for address in addresses:
                if address["type"] == "InternalIP":
                    node_internalip = address["address"]
                    break
            else:
                node_internalip = None
            self.inventory["group"]["hosts"].append(node_internalip)

            self.inventory["_meta"]["hostvars"][node_internalip] = {}
            node_name = node["metadata"]["name"]
            self.inventory["_meta"]["hostvars"][node_internalip][
                "kube_node_name"] = node_name
            if not self._set_ssh_keys(
                    node["metadata"]["annotations"],
                    node_internalip, node_name):
                self._set_default_ssh_keys(node_internalip)
            # As the annotations are not of interest so
            # not adding them to ansible host groups
            # Only updating the host variable with annotations
            for key, value in node["metadata"]["annotations"].items():
                self.inventory["_meta"]["hostvars"]\
                        [node_internalip][key] = value
            # Add groups based on labels and also updates the host variables
            for key, value in node["metadata"]["labels"].items():
                self.inventory["_meta"]["hostvars"]\
                        [node_internalip][key] = value
                if key in interested_labels_annotations:
                    if key+'_'+value not in self.inventory.keys():
                        self.inventory[key+'_'+value] = {
                                "hosts": [], "vars": {}
                                }
                    if node_internalip not in \
                            self.inventory[key+'_'+value]["hosts"]:
                        self.inventory[key+'_'+value]\
                                ["hosts"].append(node_internalip)
            # Add groups based on node info and also updates the host variables
            for key, value in node['status']['node_info'].items():
                self.inventory["_meta"]["hostvars"]\
                        [node_internalip][key] = value
                if key in interested_labels_annotations:
                    if key+'_'+value not in self.inventory.keys():
                        self.inventory[key+'_'+value] = {
                                "hosts": [], "vars": {}
                                }
                    if node_internalip not in \
                            self.inventory[key+'_'+value]["hosts"]:
                        self.inventory[key+'_'+value]\
                                ["hosts"].append(node_internalip)
        return

    def empty_inventory(self):
        return {"_meta": {"hostvars": {}}}

    # Read the command line args passed to the script.
    def read_cli_args(self):
        parser = argparse.ArgumentParser()
        parser.add_argument("--list", action="store_true")
        parser.add_argument("--host", action="store")
        self.args = parser.parse_args()


# Do computer.
KubeInventory()
