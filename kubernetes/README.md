# Kubernetes cluster
A vagrant script for setting up a Kubernetes cluster using Kubeadm

## Pre-requisites

 * **[Vagrant 2.1.4+](https://www.vagrantup.com)**
 * **[Virtualbox 5.2.18+](https://www.virtualbox.org)**

## How to Run

Git clone the repo on the host machine which has vagrant and virtual box installed

```
git clone https://github.com/SirishaGopigiri/airship-host-config.git
```

Navigate to the kubernetes folder

```
cd airship-host-config/kubernetes/
```

Execute the following vagrant command to start a new Kubernetes cluster, this will start three master and five nodes:

```
vagrant up
```

You can also start individual machines by vagrant up k8s-head, vagrant up k8s-node-1 and vagrant up k8s-node-2

If you would need more master nodes, you can edit the servers array in the Vagrantfile. Please change the name, and IP address for eth1.
```
servers = [
    {
        :name => "k8s-master-1",
        :type => "master",
        :box => "ubuntu/xenial64",
        :box_version => "20180831.0.0",
        :eth1 => "192.168.205.10",
        :mem => "2048",
        :cpu => "2"
    }
]
```
Also update the haproxy.cfg file to add more master servers. 

```
    balance     roundrobin
        server k8s-api-1 192.168.205.10:6443 check
        server k8s-api-2 192.168.205.11:6443 check
        server k8s-api-3 192.168.205.12:6443 check
        server k8s-api-4 <ip:port> check
```


If more than five nodes are required, you can edit the servers array in the Vagrantfile. Please change the name, and IP address for eth1.

```
servers = [
    {
        :name => "k8s-node-3",
        :type => "node",
        :box => "ubuntu/xenial64",
        :box_version => "20180831.0.0",
        :eth1 => "192.168.205.14",
        :mem => "2048",
        :cpu => "2"
    }
]
 ```

As you can see above, you can also configure IP address, memory and CPU in the servers array. 

## Clean-up

Execute the following command to remove the virtual machines created for the Kubernetes cluster.
```
vagrant destroy -f
```

You can destroy individual machines by vagrant destroy k8s-node-1 -f
