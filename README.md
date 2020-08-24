# Airship HostConfig Operator

A Day-2 host management interface for Kubernetes

This repo contains the code for Airship HostConfig Operator
built on Ansible Operator

## How to Run

## Approach 1
If Kubernetes setup is not available you can build up using
the scripts in tools/deployment folder. The scripts bring up a
kind based 3 master and 5 worker node setup.

Please follow the below steps to bring up the kubernetes setup
and then launch the hostconfig-operator pod for testing.

1. Clone the repository
```
git clone https://opendev.org/airship/hostconfig-operator.git
cd hostconfig-operator
```

2. To install kind, kubectl and operator-sdk utilities
```
./tools/deployment/00_install_kind.sh
./tools/deployment/01_install_kubectl.sh
./tools/deployment/02_install_operator_sdk.sh
```

3. Create hostconfig kind cluster
```
./tools/deployment/10_create_hostconfig_cluster.sh
```

4. Configure SSH on the kind cluster nodes and create labels
on the nodes
```
./tools/deployment/20_configure_ssh_on_nodes.sh
./tools/deployment/30_create_labels.sh
```

5. Deploy HostConfig Operator on the kubernetes master node
```
./tools/deployment/40_deploy_hostconfig_operator.sh
```
Check for hostconfig-operator pod status. It should come to
running state.

## Approach 2
If Kubernetes setup is already available, please follow the
below procedure

 ** Pre-requisites: Access to kubernetes setup using kubectl **

Set the Kubeconfig variable
```
export KUBECONFIG=~/.kube/config
```

Clone the repository

```
git clone https://opendev.org/airship/hostconfig-operator.git
cd hostconfig-operator
```

1. Configure SSH keys and creates kubernetes secrets and
annotations on nodes. Pre-requisite for the script is that SSH
should be already installed and configured on the nodes. And a
sample SSH user which can be used by the hostconfig-operator to
connect to nodes should be already configured on the nodes.
```
./tools/install_ssh_private_key.sh <username> <password>
```

2. Deploy HostConfig Operator on the kubernetes cluster.
```
./tools/deployment/40_deploy_hostconfig_operator.sh
```
Check for hostconfig-operator pod status. It should come to
running state.

3. Before executing any HostConfig CR objects, please label
the nodes appropriately. There is a sample 30_create_labels.sh
script available in tools/deployment folder for reference.
The valid labels that can be configured in the HostConfig CR are:
    * [`topology.kubernetes.io/region`](https://kubernetes.io/docs/reference/kubernetes-api/labels-annotations-taints/#topologykubernetesiozone)
    * [`topology.kubernetes.io/zone`](https://kubernetes.io/docs/reference/kubernetes-api/labels-annotations-taints/#topologykubernetesioregion)
    * [`kubernetes.io/hostname`](https://kubernetes.io/docs/reference/kubernetes-api/labels-annotations-taints/#kubernetes-io-hostname)
    * [`kubernetes.io/arch`](https://kubernetes.io/docs/reference/kubernetes-api/labels-annotations-taints/#kubernetes-io-arch)
    * [`kubernetes.io/os`](https://kubernetes.io/docs/reference/kubernetes-api/labels-annotations-taints/#kubernetes-io-os)
    * `kubernetes.io/role`


## SSH Keys

For hostconfig operator to use your own custom keys or custom
secret names, follow the below commands to generate the private
and public keys. Use this private key and username to generate
the kuberenetes secret. Once the secret is available attach
this secret name as annotation to the kubernetes node. Also
copy the public key to the node.

```
ssh-keygen -q -t rsa -N '' -f <key_file_name>
ssh-copy-id -i <key_file_name> <username>@<node_ip>
kubectl create secret generic <secret_name> \
--from-literal=username=<username> \
--from-file=ssh_private_key=<key_file_name>
kubectl annotate node <node_name> secret=<secret_name>
```

## Run Examples

After the scrits are executed successfully and once the
hostconfig operator pod comes to running state, navigate
to demo_examples and execute the desired examples.

Before executing the examples keep tailing the logs of the
airship-host-config pod to see the ansible playbook getting
executed while running the examples. Or you can as well
check the status of the CR object created

```
kubectl get pods
kubectl logs -f <airship-host-config-pod-name>
```

Executing examples

```
cd demo_examples
kubectl apply -f example_host_groups.yaml
kubectl apply -f example_match_host_groups.yaml
kubectl apply -f example_parallel.yaml
```
To check the status of the hostconfig CR object you have
executed you can use the kubectl command.

```
kubectl get hostconfig <hostconfig_cr_name> -o json
```

This displays the detailed output of each task that
has been executed.

You can as well check the working of the operator by
executing the validation scripts available.
```
./tools/deployment/50_test_hostconfig_cr.sh
./tools/deployment/51_test_hostconfig_cr_reconcile.sh
```
These scripts execute some sample CR's and check the execution.

## Airship HostConfig Operator CR object specification variables

Here we discuss about the various variable that can be used in
the HostConfig CR Object to control the execution flow of the
kubernetes nodes.

host_groups: Dictionary specifying the key/value labels of the
Kubernetes nodes on which the playbook should be executed.

sequential: When set to true executes the host_groups labels sequentially.

match_host_groups: Performs an AND operation of the host_group labels
and executes the playbook on those hosts only which have all the labels
matched, when set to true.

max_hosts_parallel: Caps the numbers of hosts that are executed
in each iteration.

stop_on_failure: When set to true stops the playbook execution
on that host and subsequent hosts whenever a task fails on a node.

max_failure_percentage: Sets the Maximum failure percentage of
hosts that are allowed to fail on a every iteration.

Annotations:

reconcile_period: Executes the CR object for every period of time
given in the annotation.

reconcile_iterations: Limits the number of iterations of
reconcile-period to the number of iterations specified.

reconcile_interval: Runs the CR object with the frequency give as
reconcile-period, for an interval of time given as reconcile_interval.

Config Roles:

ulimit, sysctl: Array objects specifiying the configuration of
ulimit and sysctl on the kubernetes nodes.

kubeadm, shell: Array objects specifiying the kubeadm and shell
commands that world be executed on the kubernetes nodes.

The demo_examples folder has some examples listed which can be
used to initially to play with the above variables

1. example_host_groups.yaml - Gives example on how to use host_groups

2. example_sequential.yaml - In this example the host_groups specified
goes by sequence and in the first iteration the master nodes gets
executed and then the worker nodes get executed

3. example_match_host_groups.yaml - In this example the playbook will
be executed on all the hosts matching "us-east-1a" zone and are
master nodes, "us-east-1a" and are worker nodes, "us-east-1b" and
are "master" nodes, "us-east-1b" and are worker nodes.
All the hosts matching the condition will be executed in parallel.

4. example_sequential_match_host_groups.yaml - This is the same example
as above but just that the execution goes in sequence.

5. example_parallel.yaml - In this example we will be executing on
only 2 hosts for every iteration.

6. example_stop_on_failure.yaml - This example shows that the execution
stops whenever a task fails on any kubernetes hosts

7. example_max_percentage.yaml - In this example the execution stops
only when the hosts failing exceeds 30% at a given iteration.

8. example_sysctl_ulimit.yaml - In this example we configure the kubernetes
nodes with the values specified for ulimit and sysclt in the CR object.

9. example_reconcile.yaml - Gives an example on how to use
reconcile annotation to run the HostConfig CR periodically
at the given frequecny in the annotation.

10. example_reconcile_iterations.yaml - In this example the CR objects
executes at the given frequency in the "reconcile-period" annotation for
only fixed number of times specified in the "reconcile-iterations" annotation.

11. example_reconcile_interval.yaml - Gives an example to run CR objects
at a particular frquency for a particular interval of time,
specified as "reconcile-interval" annotation.
