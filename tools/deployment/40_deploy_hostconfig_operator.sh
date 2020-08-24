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

export HOSTCONFIG_WS=${HOSTCONFIG_WS:-$PWD}
export HOSTCONFIG=${HOSTCONFIG:-"$HOSTCONFIG_WS/airship-host-config"}
export IMAGE_NAME=${IMAGE_NAME:-"airship-hostconfig:local"}

# Building hostconfig image
cd $HOSTCONFIG
operator-sdk build $IMAGE_NAME

# Copying hostconfig image to nodes
kind load docker-image $IMAGE_NAME --name hostconfig

# Deploying HostConfig Operator Pod
cd $HOSTCONFIG_WS
sed -i "s/AIRSHIP_HOSTCONFIG_IMAGE/$IMAGE_NAME/g" $HOSTCONFIG/deploy/operator.yaml
sed -i "s/PULL_POLICY/IfNotPresent/g" $HOSTCONFIG/deploy/operator.yaml

kubectl apply -f $HOSTCONFIG/deploy/crds/hostconfig.airshipit.org_hostconfigs_crd.yaml
kubectl apply -f $HOSTCONFIG/deploy/role.yaml
kubectl apply -f $HOSTCONFIG/deploy/service_account.yaml
kubectl apply -f $HOSTCONFIG/deploy/role_binding.yaml
kubectl apply -f $HOSTCONFIG/deploy/cluster_role_binding.yaml
kubectl apply -f $HOSTCONFIG/deploy/operator.yaml

kubectl wait --for=condition=available deploy --all --timeout=1000s -A

kubectl get pods -o wide

kubectl get pods -A

kubectl get nodes -o wide --show-labels
