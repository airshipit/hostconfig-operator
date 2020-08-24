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

#Default wait timeout is 3600 seconds
export TIMEOUT=${TIMEOUT:-3600}
REMOTE_WORK_DIR=/tmp

echo "Create Kind Cluster"
cat <<EOF >  ${REMOTE_WORK_DIR}/kind-hostconfig.yaml
kind: Cluster
apiVersion: kind.sigs.k8s.io/v1alpha3
nodes:
  - role: control-plane
  - role: control-plane
  - role: control-plane
  - role: worker
  - role: worker
EOF

kind create cluster --config ${REMOTE_WORK_DIR}/kind-hostconfig.yaml --name hostconfig -v 2

#Wait till HostConfig Cluster is ready
end=$(($(date +%s) + $TIMEOUT))
echo "Waiting $TIMEOUT seconds for HostConfig Cluster to be ready."

hosts=(`kubectl get nodes -o wide | awk '{print $1}' | sed -e '1d'`)

for i in "${!hosts[@]}"
do
    while true; do
        if (kubectl --request-timeout 20s get nodes ${hosts[i]} -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q True) ; then
            echo -e "\nHostConfig Cluster Nodes are ready."
            kubectl --request-timeout 20s get nodes
            break
        else
            now=$(date +%s)
            if [ $now -gt $end ]; then
                echo -e "\nHostConfig Cluster Nodes were not ready before TIMEOUT."
                exit 1
            fi
        fi
        echo -n .
        sleep 15
    done
done
