#!/bin/bash

if [[ $1 ]] && [[ $2 ]]; then
    USERNAME=$1
    PASSWORD=$2

    hosts=(`kubectl get nodes -o wide | awk '{print $1}' | sed -e '1d'`)
    hosts_ips=(`kubectl get nodes -o wide | awk '{print $6}' | sed -e '1d'`)
    for i in "${!hosts[@]}"
    do
        printf 'Working on host %s with Index %s and having IP %s\n' "${hosts[i]}" "$i" "${hosts_ips[i]}"
        ssh-keygen -q -t rsa -N '' -f ${hosts[i]}
        sshpass -p $PASSWORD ssh-copy-id -o StrictHostKeyChecking=no -i ${hosts[i]} $USERNAME@${hosts_ips[i]}
        kubectl create secret generic ${hosts[i]} --from-literal=username=$USERNAME --from-file=ssh_private_key=${hosts[i]}
        kubectl annotate node ${hosts[i]} secret=${hosts[i]}
    done
else
    echo "Please send username/password as arguments to the script."
fi
