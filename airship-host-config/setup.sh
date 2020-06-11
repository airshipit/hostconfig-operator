#!/bin/bash

RELEASE_VERSION=v0.8.0
AIRSHIP_PATH=airship-host-config/airship-host-config
IMAGE_NAME=airship-host-config

install_operator_sdk(){
    echo "Installing Operator-SDK to build image"
    curl -OJL https://github.com/operator-framework/operator-sdk/releases/download/${RELEASE_VERSION}/operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu
    chmod +x operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu
    sudo mv operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu /usr/local/bin/operator-sdk
}

build_host_config_image(){
    echo "Building Airship host-config Ansible operator Image"
    cd $HOME/$AIRSHIP_PATH
    operator-sdk build $IMAGE_NAME
}

get_worker_ips(){
    echo >&2 "Getting other master and worker node IPs to copy Airship host-config Ansible Operator Image"
    IP_ADDR=`ifconfig enp0s8 | grep Mask | awk '{print $2}'| cut -f2 -d:`
    worker_node_ips=`kubectl get nodes -o wide | grep -v $IP_ADDR | awk '{print $6}' | sed -e '1d'`
    echo $worker_node_ips
}

save_and_load_docker_image(){
    cd $HOME/$AIRSHIP_PATH
    echo "Saving Airship host-config Ansible Operator Image so that it would be copied to other worker nodes"
    docker save $IMAGE_NAME -o $IMAGE_NAME
    worker_node_ips=$(get_worker_ips)
    echo "Copying Image to following worker Nodes"
    echo $worker_node_ips
    for i in $worker_node_ips
    do
        sshpass -p "vagrant" scp -o StrictHostKeyChecking=no $IMAGE_NAME vagrant@$i:~/.
        sshpass -p "vagrant" ssh vagrant@$i docker load -i $IMAGE_NAME
    done
}

get_username_password(){
    if [ -z "$1" ]; then USERNAME="vagrant"; else USERNAME=$1; fi
    if [ -z "$2" ]; then PASSWORD="vagrant"; else PASSWORD=$2; fi
    echo $USERNAME $PASSWORD
}

deploy_airship_ansible_operator(){
    read USERNAME PASSWORD < <(get_username_password $1 $2)
    echo "Setting up Airship host-config Ansible operator"
    echo "Using Username: $USERNAME and Password: $PASSWORD of K8 nodes for host-config pod setup"
    sed -i "s/AIRSHIP_HOSTCONFIG_IMAGE/$IMAGE_NAME/g" $HOME/$AIRSHIP_PATH/deploy/operator.yaml
    sed -i "s/PULL_POLICY/IfNotPresent/g" $HOME/$AIRSHIP_PATH/deploy/operator.yaml
    sed -i "s/USERNAME/$USERNAME/g" $HOME/$AIRSHIP_PATH/deploy/operator.yaml
    sed -i "s/PASSWORD/$PASSWORD/g" $HOME/$AIRSHIP_PATH/deploy/operator.yaml
    kubectl apply -f $HOME/$AIRSHIP_PATH/deploy/crds/hostconfig.airshipit.org_hostconfigs_crd.yaml
    kubectl apply -f $HOME/$AIRSHIP_PATH/deploy/role.yaml
    kubectl apply -f $HOME/$AIRSHIP_PATH/deploy/service_account.yaml
    kubectl apply -f $HOME/$AIRSHIP_PATH/deploy/role_binding.yaml
    kubectl apply -f $HOME/$AIRSHIP_PATH/deploy/cluster_role_binding.yaml
    kubectl apply -f $HOME/$AIRSHIP_PATH/deploy/operator.yaml
}

configure_github_host_config_setup(){
   install_operator_sdk
   build_host_config_image
   save_and_load_docker_image
   deploy_airship_ansible_operator $1 $2
}

configure_github_host_config_setup $1 $2
