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
        failures=$(kubectl get hostconfig $hostconfig -o jsonpath='{.status.ansibleSummary.failures}')
        unreachable=$(kubectl get hostconfig $hostconfig -o jsonpath='{.status.ansibleSummary.unreachable}')
        # Checking for failures and unreachable hosts in the HostConfig CR
        if [[ $failures == "map[]" && $unreachable == "map[]" ]]; then
            hosts=$2
            ok=$(kubectl get hostconfig $hostconfig -o json | jq '.status.ansibleSummary.ok | keys')
            echo $ok
            hostNames=$(kubectl get hostconfig $hostconfig -o json | jq '.status.hostConfigStatus | keys')
            ok_array=${ok[@]}
            hostNames_array=${hostNames[@]}
            # Checking of all the hosts has executed
            if [ "$hosts" == "$ok_array" ] && [ "$hosts" == "$hostNames_array" ]; then
                reconcile=$(kubectl get hostconfig $hostconfig -o "jsonpath={.status.reconcileStatus.msg}")
                reconcilemsg=$3
                if [[ $reconcile == $reconcilemsg ]]; then
                    # Checking if the reconciles has completed
                    echo "$hostconfig hostconfig executed successfully"
                    return 0
                else
                    # Waiting for reconcile executions to complete
                    now=$(date +%s)
                    if [ $now -gt $end ]; then
                        echo -e "HostConfig CR execution not completed even after timeout"
                        exit 1
                    fi
                fi
            else
                echo "$hostconfig hostconfig execution failed!"
                exit 1
            fi
        elif [ -z "$failures" ] && [ -z "$unreachable" ]; then
            # Checking for status till timeout has reached
            now=$(date +%s)
            if [ $now -gt $end ]; then
                echo -e "HostConfig CR execution not completed even after timeout"
                exit 1
            fi
        else
            # Failing execution if HostConfig CR has failed
            echo "HostConfig CR execution failed"
            exit 1
        fi
        sleep 30
    done
}

# Executing HostConfig CR in simple reconcile loop
kubectl apply -f $AIRSHIP_HOSTCONFIG/demo_examples/example_reconcile.yaml
hosts=("hostconfig-control-plane" "hostconfig-control-plane2" "hostconfig-control-plane3")
check_status example9 '[ "hostconfig-control-plane", "hostconfig-control-plane2", "hostconfig-control-plane3" ]' "Reconcile iterations or interval not specified. Running simple reconcile."
kubectl delete -f $AIRSHIP_HOSTCONFIG/demo_examples/example_reconcile.yaml

# Executing HostConfig CR with reconcile_iterations configuration
kubectl apply -f $AIRSHIP_HOSTCONFIG/demo_examples/example_reconcile_iterations.yaml
hosts=("hostconfig-control-plane" "hostconfig-control-plane2" "hostconfig-control-plane3")
check_status example10 '[ "hostconfig-control-plane", "hostconfig-control-plane2", "hostconfig-control-plane3" ]' "Running reconcile completed. Total iterations completed are 3"
kubectl delete -f $AIRSHIP_HOSTCONFIG/demo_examples/example_reconcile_iterations.yaml

# Executing HostConfig CR with reconcile_interval configuration
kubectl apply -f $AIRSHIP_HOSTCONFIG/demo_examples/example_reconcile_interval.yaml
hosts=("hostconfig-control-plane" "hostconfig-control-plane2" "hostconfig-control-plane3")
check_status example11 '[ "hostconfig-control-plane", "hostconfig-control-plane2", "hostconfig-control-plane3" ]' "Running reconcile completed. Total iterations completed are 5"
kubectl delete -f $AIRSHIP_HOSTCONFIG/demo_examples/example_reconcile_interval.yaml
