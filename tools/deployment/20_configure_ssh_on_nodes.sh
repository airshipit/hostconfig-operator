#!/usr/bin/env bash

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -xe

hosts=(`kubectl get nodes -o wide | awk '{print $1}' | sed -e '1d'`)
hosts_ips=(`kubectl get nodes -o wide | awk '{print $6}' | sed -e '1d'`)

export USERNAME=${USERNAME:-"hostconfig"}
export PASSWORD=${PASSWORD:-"hostconfig"}

# Installing openssl, sshpass and jq modules
sudo apt-get install -y openssl sshpass jq
ENCRYPTED_PASSWORD=`openssl passwd -crypt $PASSWORD`

# Configuring SSH on Kubernetes nodes
for i in "${!hosts[@]}"
do
    sudo docker exec ${hosts[i]} apt-get update
    sudo docker exec ${hosts[i]} apt-get install -y sudo openssh-server
    sudo docker exec ${hosts[i]} service sshd start
    sudo docker exec ${hosts[i]} useradd -m -p $ENCRYPTED_PASSWORD -s /bin/bash $USERNAME
    sudo docker exec ${hosts[i]} bash -c "echo '$USERNAME ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/hostconfig"
    printf 'Working on host %s with Indexs and having IP %s\n' "${hosts[i]}" "$i" "${hosts_ips[i]}"
    ssh-keygen -q -t rsa -N '' -f ${hosts[i]}
    sshpass -p $PASSWORD ssh-copy-id -o StrictHostKeyChecking=no -i ${hosts[i]} $USERNAME@${hosts_ips[i]}
    kubectl create secret generic ${hosts[i]} --from-literal=username=$USERNAME --from-file=ssh_private_key=${hosts[i]}
    kubectl annotate node ${hosts[i]} secret=${hosts[i]}
done
