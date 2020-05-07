#!/usr/bin/env python

import os
import sys
import argparse
import time
import kubernetes.client
from kubernetes.client.rest import ApiException
import yaml

import json


class KubeInventory(object):
    def __init__(self):
        self.inventory = {}
        self.read_cli_args()

        if self.args.list:
            self.inventory = self.kube_inventory()
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
        self.inventory["group"]["vars"]["ansible_ssh_user"] = "deployer"
        self.inventory["group"]["vars"][
            "ansible_ssh_private_key_file"
        ] = "~/.ssh/id_rsa.pem"

        api_instance = kubernetes.client.CoreV1Api(kubernetes.config.load_incluster_config())
        #api_instance = kubernetes.client.CoreV1Api(kubernetes.config.load_kube_config())

        #TODO: read from env var
        label_selector = "kubernetes.io/hostname=kind-control-plane"

        try:
            nodes = api_instance.list_node(label_selector=label_selector).to_dict()[
                "items"
            ]
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
            self.inventory["_meta"]["hostvars"][node_internalip][
                "kube_node_name"
            ] = node["metadata"]["name"]

        return self.inventory

    # Empty inventory.
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
