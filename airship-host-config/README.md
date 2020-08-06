# Airship HostConfig Using Ansible Operator

Here we discuss about the various variable that are used in the HostConfig CR Object to control the execution flow of the kubernetes nodes

host_groups: Dictionary specifying the key/value labels of the Kubernetes nodes on which the playbook should be executed

sequential: When set to true executes the host_groups labels sequentially

match_host_groups: Performs an AND operation of the host_group labels and executes the playbook on the hosts which have all the labels matched, when set to true

max_hosts_parallel: Caps the numbers of hosts that are executed in each iteration

stop_on_failure: When set to true stops the playbook execution on that host and subsequent hosts whenever a task fails on a node

max_failure_percenatge: Sets the Maximum failure percenatge of hosts that are allowed to fail on a every iteration

reexecute: Executes the playbook again on the successful hosts as well

ulimit, sysctl: Array objects specifiying the configuration of ulimit and sysctl on the kubernetes nodes

The demo_examples folder has some examples listed which can be used to initially to play with the above variables

1. example_host_groups.yaml - Gives example on how to use host_groups
 
2. example_sequential.yaml - In this example the host_groups specified goes by sequence and in the first iteration the master nodes get executed and then the worker nodes get executed

3. example_match_host_groups.yaml - In this example the playbook will be executed on all the hosts matching "us-east-1a" zone and are master nodes, "us-east-1a" and are worker nodes, "us-east-1b" and are "master" nodes, "us-east-1b" and are worker nodes. All the hosts matching the condition will be executed in parallel.

4. example_sequential_match_host_groups.yaml - This is the same example as above but just the execution goes in sequence

5. example_parallel.yaml - In this example we will be executing 2 hosts for every iteration

6. example_stop_on_failure.yaml - This example shows that the execution stops whenever a task fails on any kubernetes hosts

7. example_max_percentage.yaml - In this example the execution stops only when the hosts failing exceeds 30% at a given iteration.

8. example_sysctl_ulimit.yaml - In this example we configure the kubernetes nodes with the values specified for ulimit and sysclt in the CR object.
