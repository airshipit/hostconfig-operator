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

export TIMEOUT=${TIMEOUT:-3600}
export AIRSHIP_HOSTCONFIG=${AIRSHIP_HOSTCONFIG:-$PWD}

check_status(){
    hostconfig=$1
    echo $2
    end=$(($(date +%s) + $TIMEOUT))
    while true; do
        failures=$(kubectl get hostconfig $hostconfig -o json | jq ".status.ansibleSummary.failures | length")
        unreachable=$(kubectl get hostconfig $hostconfig -o jsonpath='{.status.ansibleSummary.unreachable}')
        # Checking for number of failed hosts and unreachable hosts
        if [[ $failures == $3 && $unreachable == "map[]" ]]; then
            hosts=$2
            ok=$(kubectl get hostconfig $hostconfig -o json | jq '.status.ansibleSummary.ok | keys')
            ok_array=${ok[@]}
            # Checking if all the remaining hosts has executed successfully
            if [ "$hosts" == "$ok_array" ]; then
                 echo "$hostconfig hostconfig executed successfully"
                 return 0
            else
                 echo "$hostconfig hostconfig execution failed!"
                 exit 1
            fi
        elif [ $failures == 0 ] && [ -z "$unreachable" ]; then
            # Waiting for HostConfig CR to complete and stopping after timeout
            now=$(date +%s)
            if [ $now -gt $end ]; then
                echo -e "HostConfig CR execution not completed even after timeout"
                exit 1
            fi
        else
            # Stopping execution of incase if the HostConfig CR fails
            echo "HostConfig CR execution failed"
            exit 1
        fi
        sleep 30
    done
}

# Removing sudo access for the user so that the execution node fails
sudo docker exec hostconfig-control-plane3 rm -rf /etc/sudoers.d/hostconfig

# Executing the stop_on_failure example
kubectl apply -f $AIRSHIP_HOSTCONFIG/demo_examples/example_stop_on_failure.yaml
check_status example6 '[ "hostconfig-control-plane", "hostconfig-control-plane2" ]' 1

# Executing the max failure nodes example
kubectl apply -f $AIRSHIP_HOSTCONFIG/demo_examples/example_max_percentage.yaml
check_status example5 '[ "hostconfig-control-plane", "hostconfig-control-plane2" ]' 1
kubectl delete -f $AIRSHIP_HOSTCONFIG/demo_examples/example_max_percentage.yaml

# Failing more master nodes
sudo docker exec hostconfig-control-plane2 rm -rf /etc/sudoers.d/hostconfig

kubectl apply -f $AIRSHIP_HOSTCONFIG/demo_examples/example_max_percentage.yaml
check_status example5 '[ "hostconfig-control-plane" ]' 2
kubectl delete -f $AIRSHIP_HOSTCONFIG/demo_examples/example_max_percentage.yaml
