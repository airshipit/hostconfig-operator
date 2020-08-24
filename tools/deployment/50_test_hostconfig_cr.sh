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
                if $3; then
                    # Checking if the execution has happened in sequence
                    # based on the date command executed on the nodes at the time of execution
                    # Please refer to the demo_examples sample CRs for the configuration
                    loop=$4
                    shift 4
                    pre_hosts_date=""
                    for ((i=0;i<loop;i++)); do
                        hosts=( "${@:2:$1}" ); shift "$(( $1 + 1 ))"
                        pre_host_date=""
                        for j in "${!hosts[@]}"; do
                            kubectl_stdout=$(kubectl get hostconfig $hostconfig -o "jsonpath={.status.hostConfigStatus.${hosts[j]}.Execute\ shell\ command\ on\ nodes.results[0].stdout}" | head -1)
                            echo $kubectl_stdout
                            host_date=$(date --date="$kubectl_stdout" +"%s")
                            if [ ! -z "$pre_host_date" ]; then
                                differ=$((pre_host_date-host_date))
                                if [[ $differ -lt 0 ]]; then
                                    differ=${differ#-}
                                fi
                                if [[ $differ -gt 5 ]] ; then
                                    echo "HostConfig CR $hostconfig didn't execute in sequence!"
                                    exit 1
                                fi
                            fi
                            pre_host_date=$host_date
                            hosts_date=$host_date
                        done
                        if [ ! -z "$hosts_date" ] && [ ! -z "$pre_hosts_date" ]; then
                            hosts_differ=$((hosts_date-pre_hosts_date ))
                            if [[ $hosts_differ -lt 0 ]]; then
                                hosts_differ=${hosts_differ#-}
                            fi
                            if [[ $hosts_differ -lt 5 ]]; then
                                echo "HostConfig CR $hostconfig didn't execute in sequence!"
                                exit 1
                            fi
                        fi
                        pre_hosts_date=$hosts_date
                    done
                fi
                echo "$hostconfig hostconfig executed successfully"
                return 0
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

# Checking HostConfig CR with host_groups configuration
kubectl apply -f $AIRSHIP_HOSTCONFIG/demo_examples/example_host_groups.yaml
hosts=("hostconfig-control-plane" "hostconfig-control-plane2" "hostconfig-control-plane3")
check_status example1 '[ "hostconfig-control-plane", "hostconfig-control-plane2", "hostconfig-control-plane3" ]' false

# Checking HostConfig CR, if nodes are executing in sequence
kubectl apply -f $AIRSHIP_HOSTCONFIG/demo_examples/example_sequential.yaml
hosts1=("hostconfig-control-plane" "hostconfig-control-plane2" "hostconfig-control-plane3")
hosts2=("hostconfig-worker" "hostconfig-worker2")
check_status example2 '[ "hostconfig-control-plane", "hostconfig-control-plane2", "hostconfig-control-plane3", "hostconfig-worker", "hostconfig-worker2" ]' true 2 "${#hosts1[@]}" "${hosts1[@]}" "${#hosts2[@]}" "${hosts2[@]}"

# Checking if the nodes are matched with the given labels in the host_groups
kubectl apply -f $AIRSHIP_HOSTCONFIG/demo_examples/example_match_host_groups.yaml
check_status example3 '[ "hostconfig-control-plane", "hostconfig-control-plane3", "hostconfig-worker" ]' false

# Checking if the executing is happening in sequence on the host_groups matched
kubectl apply -f $AIRSHIP_HOSTCONFIG/demo_examples/example_sequential_match_host_groups.yaml
hosts1=("hostconfig-control-plane")
hosts2=("hostconfig-worker")
hosts3=("hostconfig-control-plane3")
check_status example4 '[ "hostconfig-control-plane", "hostconfig-control-plane3", "hostconfig-worker" ]' true 3 "${#hosts1[@]}" "${hosts1[@]}" "${#hosts2[@]}" "${hosts2[@]}" "${#hosts3[@]}" "${hosts3[@]}"

# Executing configuration on hosts in parallel with the given number of hosts getting executed in sequence
kubectl apply -f $AIRSHIP_HOSTCONFIG/demo_examples/example_parallel.yaml
check_status example7 '[ "hostconfig-control-plane", "hostconfig-control-plane2", "hostconfig-control-plane3", "hostconfig-worker", "hostconfig-worker2" ]' false

# Executing sample sysctl and ulimit configuration on the kubernetes nodes
kubectl apply -f $AIRSHIP_HOSTCONFIG/demo_examples/example_sysctl_ulimit.yaml
check_status example8 '[ "hostconfig-control-plane", "hostconfig-control-plane2", "hostconfig-control-plane3" ]' false
