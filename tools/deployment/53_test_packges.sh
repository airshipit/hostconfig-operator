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
    end=$(($(date +%s) + $TIMEOUT))
    while true; do
        # Getting the failed and unreachable nodes status
        failures=$(kubectl get hostconfig $hostconfig -o jsonpath='{.status.ansibleSummary.failures}')
        unreachable=$(kubectl get hostconfig $hostconfig -o jsonpath='{.status.ansibleSummary.unreachable}')
        if [[ $failures == "map[]" && $unreachable == "map[]" ]]; then
            kubectl get hostconfig $hostconfig -o json
            hosts=$2
            ok=$(kubectl get hostconfig $hostconfig -o json | jq '.status.ansibleSummary.ok | keys')
            hostNames=$(kubectl get hostconfig $hostconfig -o json | jq '.status.hostConfigStatus | keys')
            ok_array=${ok[@]}
            hostNames_array=${hostNames[@]}
            # Checking if all hosts has executed
            if [ "$hosts" == "$ok_array" ] && [ "$hosts" == "$hostNames_array" ]; then
                if [[ `sudo docker exec $3 bash -- which apache2` && `sudo docker exec $3 bash -- which openstack` ]]; then
                    echo "$hostconfig hostconfig executed successfully"
                    return 0
                else
                    echo "$hostconfig hostconfig execution failed!"
                    return 1
                fi
            else
                # Failing the execution is the hosts hasn't matched.
                echo "$hostconfig hostconfig execution failed!"
                exit 1
            fi
        elif [ -z "$failures" ] && [ -z "$unreachable" ]; then
            # Waiting for the HostConfig CR status till timeout is reached.
            now=$(date +%s)
            if [ $now -gt $end ]; then
                kubectl get hostconfig $hostconfig -o json
                echo -e "HostConfig CR execution not completed even after timeout"
                exit 1
            fi
        else
            # Failing the execution if the HostConfig CR object execution has failed.
            kubectl get hostconfig $hostconfig -o json
            echo "HostConfig CR execution failed"
            exit 1
        fi
        sleep 30
    done
}

# Checking HostConfig CR packages installation
kubectl apply -f $AIRSHIP_HOSTCONFIG/demo_examples/example_packages.yaml
check_status example-packages '[ "hostconfig-control-plane" ]' "hostconfig-control-plane"
