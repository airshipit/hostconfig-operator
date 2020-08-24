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

# Labeling kubernetes nodes with role
kubectl label node hostconfig-control-plane kubernetes.io/role=master
kubectl label node hostconfig-control-plane2 kubernetes.io/role=master
kubectl label node hostconfig-control-plane3 kubernetes.io/role=master
kubectl label node hostconfig-worker kubernetes.io/role=worker
kubectl label node hostconfig-worker2 kubernetes.io/role=worker

# Labeling kubernetes nodes with region
kubectl label node hostconfig-control-plane topology.kubernetes.io/region=us-east
kubectl label node hostconfig-control-plane2 topology.kubernetes.io/region=us-west
kubectl label node hostconfig-control-plane3 topology.kubernetes.io/region=us-east
kubectl label node hostconfig-worker topology.kubernetes.io/region=us-east
kubectl label node hostconfig-worker2 topology.kubernetes.io/region=us-west

# Labeling kubernetes nodes with zone
kubectl label node hostconfig-control-plane topology.kubernetes.io/zone=us-east-1a
kubectl label node hostconfig-control-plane2 topology.kubernetes.io/zone=us-west-1a
kubectl label node hostconfig-control-plane3 topology.kubernetes.io/zone=us-east-1b
kubectl label node hostconfig-worker topology.kubernetes.io/zone=us-east-1a
kubectl label node hostconfig-worker2 topology.kubernetes.io/zone=us-west-1a
