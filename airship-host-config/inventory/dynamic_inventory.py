#!/usr/bin/env python3

import os
import sys
import argparse
import time
import kubernetes.client
from kubernetes.client.rest import ApiException
import yaml

import json

interested_labels_annotations = ["beta.kubernetes.io/arch", "beta.kubernetes.io/os", "kubernetes.io/arch", "kubernetes.io/hostname", "kubernetes.io/os", "kubernetes.io/role", "topology.kubernetes.io/region", "topology.kubernetes.io/zone", "projectcalico.org/IPv4Address", "projectcalico.org/IPv4IPIPTunnelAddr", "Kernel Version", "OS Image", "Operating System", "Container Runtime Version", "Kubelet Version", "Operating System"]

class KubeInventory(object):

    def __init__(self):
        self.inventory = {}
        self.read_cli_args()

        self.api_instance = kubernetes.client.CoreV1Api(kubernetes.config.load_incluster_config())
        if self.args.list:
#            self.inventory = self.kube_inventory()
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
        self.inventory = {"group": {"hosts": [], "vars": {}}, "_meta": {"hostvars": {}}}
        self.set_ssh_keys()
        self.get_nodes()

    def set_ssh_keys(self):
        self.inventory["group"]["vars"]["ansible_ssh_user"] = os.environ.get("USER") if "USER" in os.environ else "kubernetes"
        if "PASS" in os.environ:
            self.inventory["group"]["vars"]["ansible_ssh_pass"] = os.environ.get("PASS")
        else:
            self.inventory["group"]["vars"][
                "ansible_ssh_private_key_file"
            ] = "~/.ssh/id_rsa"
        return

    def get_nodes(self):
        #label_selector = "kubernetes.io/role="+role

        try:
            nodes = self.api_instance.list_node().to_dict()[
                "items"
            ]
            #nodes = self.api_instance.list_node(label_selector=label_selector).to_dict()[
            #   "items"
            #]
        except ApiException as e:
            print("Exception when calling CoreV1Api->list_node: %s\n" % e)

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
            for key, value in node["metadata"]["annotations"].items():
                self.inventory["_meta"]["hostvars"][node_internalip][key] = value
            for key, value in node["metadata"]["labels"].items():
                self.inventory["_meta"]["hostvars"][node_internalip][key] = value
                if key in interested_labels_annotations:
                    if value not in self.inventory.keys():
                        self.inventory[value] = {"hosts": [], "vars": {}}
                    if node_internalip not in self.inventory[value]["hosts"]:
                        self.inventory[value]["hosts"].append(node_internalip)
            for key, value in node['status']['node_info'].items():
                self.inventory["_meta"]["hostvars"][node_internalip][key] = value
                if key in interested_labels_annotations:
                    if value not in self.inventory.keys():
                        self.inventory[value] = {"hosts": [], "vars": {}}
                    if node_internalip not in self.inventory[value]["hosts"]:
                        self.inventory[value]["hosts"].append(node_internalip)
            #self.inventory["_meta"]["hostvars"][node_internalip] = {}
            self.inventory["_meta"]["hostvars"][node_internalip][
                "kube_node_name"
            ] = node["metadata"]["name"]
            #self.inventory["_meta"]["hostvars"][node_internalip]["architecture"] = node['status']['node_info']['architecture']
            #self.inventory["_meta"]["hostvars"][node_internalip]["kernel_version"] = node['status']['node_info']['kernel_version']

#        return self.inventory

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
