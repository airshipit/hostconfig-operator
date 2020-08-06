# Airship HostConfig Using Ansible Operator
This repo contains the code for Airship HostConfig Application using Ansible Operator

## How to Run

## Approach 1
If Kubernetes setup is not available please refer to README.md in kubernetes folder to bring up the kubernetes setup. It uses Vagrant and Virtual Box to bring up 3 master and 5 worker node VMs

After the VMs are up and running, connect to master node

```
vagrant ssh k8-master-1
```

Navigate to airship-host-config folder

```
cd airship-host-config/airship-host-config/
```

Execute the create_labels.sh file so that the Kubernetes nodes are labelled accordingly as master and worker nodes. We are also are attaching some sample zones and regions to the kubernetes nodes

```
./create_labels.sh
```

Please note: As part of the tasks executed whenever we are creating a Hostconfig CR object, we are checking a "hello" file in the $HOME directory of the ansible ssh user. This file is created as part of the ./setup.sh script please feel free to comment the task if not needed before builing the image.

Execute the setup.sh script to build and copy the Airship Hostconfig Ansible Operator Image to worker nodes. It also deploys the application on the Kubernetes setup as deployment kind. The below script configures Airship HostConfig Ansible Operator to use "vagrant" as both username and password when it tries connecting to the Kubernetes Nodes. So when we create a HostConfig Kubernetes CR object the application tries to execute the hostconfig ansible role on the Kubernetes Nodes specified in the CR object by connecting using the "vagrant" username and password.

```
./setup.sh
```

If you want to execute the ansible playbook in the hostconfig example with a different user, you can also set the username and password of the Kuberntes nodes when executing the setup.sh script. So this configures the HostConfig Ansible Operator pod to use the "username" and "password" passed when the hostconfig ansible role is executed on the kubernetes nodes.

```
./setup.sh <username> <password>
```

If you are planning for the ansible-operator to use username and private key when connecting to the kubernetes node. You can use the script available that creates the private and public keys, copy the public key to kubernetes nodes, creates the secret and attach the secret as annotation. 
```
./install_ssh_private_key.sh
```

To try you own custom keys or custom names, follow the below commands to generate the private and public keys. Use this private key and username to generate the kuberenetes secret. Once the secret is available attach this secret name as annotation to the kubernetes node. Also copy the public key to the node.
```
ssh-keygen -q -t rsa -N '' -f <key_file_name>
ssh-copy-id -i <key_file_name> <username>@<node_ip>
kubectl create secret generic <secret_name> --from-literal=username=<username> --from-file=ssh_private_key=<key_file_name>
kubectl annotate node <node_name> secret=<secret_name>
```

## Approach 2
If Kubernetes setup is already available, please follow the below procedure

 ** Pre-requisites: Access to kubernetes setup using kubectl **

Set the Kubeconfig variable
```
export KUBECONFIG=~/.kube/config
```

Clone the repository

```
git clone https://github.com/SirishaGopigiri/airship-host-config.git -b june_29
```

Navigate to airship-host-config folder

```
cd airship-host-config/airship-host-config/
```

Please note: As part of the tasks executed whenever we are creating a Hostconfig CR object, we are checking a "hello" file in the $HOME directory of the ansible ssh user. This file is created as part of the ./setup.sh script please feel free to comment the task if not needed before builing the image.

Execute the setup.sh script to build and copy the Airship Hostconfig Ansible Operator Image to worker nodes. It also deploys the application on the Kubernetes setup as deployment kind. The below script configures Airship HostConfig Ansible Operator to use "vagrant" as both username and password when it tries connecting to the Kubernetes Nodes. So when we create a HostConfig Kubernetes CR object the application tries to execute the hostconfig ansible role on the Kubernetes Nodes specified in the CR object by connecting using the "vagrant" username and password.

```
./setup.sh
```

If you want to execute the ansible playbook in the hostconfig example with a different user, you can also set the username and password of the Kuberntes nodes when executing the setup.sh script. So this configures the HostConfig Ansible Operator pod to use the "username" and "password" passed when the hostconfig ansible role is executed on the kubernetes nodes.

```
./setup.sh <username> <password>
```

If you are planning for the ansible-operator to use username and private key when connecting to the kubernetes node. You can use the script available that creates the private and public keys, copy the public key to kubernetes nodes, creates the secret and attach the secret as annotation.
```
./install_ssh_private_key.sh
```

To try you own custom keys or custom names, follow the below commands to generate the private and public keys. Use this private key and username to generate the kuberenetes secret. Once the secret is available attach this secret name as annotation to the kubernetes node. Also copy the public key to the node.
```
ssh-keygen -q -t rsa -N '' -f <key_file_name>
ssh-copy-id -i <key_file_name> <username>@<node_ip>
kubectl create secret generic <secret_name> --from-literal=username=<username> --from-file=ssh_private_key=<key_file_name>
kubectl annotate node <node_name> secret=<secret_name>
```


## Run Examples 

After the setup.sh file executed successfully, navigate to demo_examples and execute the desired examples

Before executing the examples keep tailing the logs of the airship-host-config pod to see the ansible playbook getting executed while running the examples

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

Apart from the logs on the pod when we execute the hostconfig role we are creating a "tetsing" file on the kubernetes nodes, please check the contents in that file which states the time of execution of the hostconfig role by the HostConfig Ansible Operator Pod.

Execute below command on the kubernetes hosts to get the timestamp of execution.

```
cat /home/vagrant/testing
```

If the setup is configured using a different user, check using the below command

```
cat /home/<username>/testing
```
