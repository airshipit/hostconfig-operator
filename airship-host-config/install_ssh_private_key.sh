#!/bin/bash

hosts=(`kubectl get nodes -o wide | awk '{print $1}' | sed -e '1d'`)
hosts_ips=(`kubectl get nodes -o wide | awk '{print $6}' | sed -e '1d'`)

get_username_password(){
    if [ -z "$1" ]; then USERNAME="vagrant"; else USERNAME=$1; fi
    if [ -z "$2" ]; then PASSWORD="vagrant"; else PASSWORD=$2; fi
    echo $USERNAME $PASSWORD
}

copy_ssh_keys(){
    read USERNAME PASSWORD < <(get_username_password $1 $2)
    for i in "${!hosts[@]}"
    do
        printf 'Working on host %s with Index %s and having IP %s\n' "${hosts[i]}" "$i" "${hosts_ips[i]}"
        ssh-keygen -q -t rsa -N '' -f ${hosts[i]}
        sshpass -p $PASSWORD ssh-copy-id -o StrictHostKeyChecking=no -i ${hosts[i]} $USERNAME@${hosts_ips[i]}
        kubectl create secret generic ${hosts[i]} --from-literal=username=$USERNAME --from-file=ssh_private_key=${hosts[i]}
        kubectl annotate node ${hosts[i]} secret=${hosts[i]}
    done
}

copy_ssh_keys $1 $2
