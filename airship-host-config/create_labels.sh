#!/bin/bash

kubectl label node k8s-master-1 kubernetes.io/role=master
kubectl label node k8s-master-2 kubernetes.io/role=master
kubectl label node k8s-master-3 kubernetes.io/role=master
kubectl label node k8s-node-1 kubernetes.io/role=worker
kubectl label node k8s-node-2 kubernetes.io/role=worker
kubectl label node k8s-node-3 kubernetes.io/role=worker
kubectl label node k8s-node-4 kubernetes.io/role=worker
kubectl label node k8s-node-5 kubernetes.io/role=worker

kubectl label node k8s-master-1 topology.kubernetes.io/region=us-east
kubectl label node k8s-master-2 topology.kubernetes.io/region=us-west
kubectl label node k8s-master-3 topology.kubernetes.io/region=us-east
kubectl label node k8s-node-1 topology.kubernetes.io/region=us-east
kubectl label node k8s-node-2 topology.kubernetes.io/region=us-east
kubectl label node k8s-node-3 topology.kubernetes.io/region=us-east
kubectl label node k8s-node-4 topology.kubernetes.io/region=us-west
kubectl label node k8s-node-5 topology.kubernetes.io/region=us-west

kubectl label node k8s-master-1 topology.kubernetes.io/zone=us-east-1a
kubectl label node k8s-master-2 topology.kubernetes.io/zone=us-west-1a
kubectl label node k8s-master-3 topology.kubernetes.io/zone=us-east-1b
kubectl label node k8s-node-1 topology.kubernetes.io/zone=us-east-1a
kubectl label node k8s-node-2 topology.kubernetes.io/zone=us-east-1a
kubectl label node k8s-node-3 topology.kubernetes.io/zone=us-east-1b
kubectl label node k8s-node-4 topology.kubernetes.io/zone=us-west-1a
kubectl label node k8s-node-5 topology.kubernetes.io/zone=us-west-1a
