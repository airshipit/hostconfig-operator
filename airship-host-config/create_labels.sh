#!/bin/bash

kubectl label node k8s-master kubernetes.io/role=master
kubectl label node k8s-node-1 kubernetes.io/role=worker
kubectl label node k8s-node-2 kubernetes.io/role=worker

kubectl label node k8s-master topology.kubernetes.io/region=us-east
kubectl label node k8s-node-1 topology.kubernetes.io/region=us-west
kubectl label node k8s-node-2 topology.kubernetes.io/region=us-east

kubectl label node k8s-master topology.kubernetes.io/zone=us-east-1a
kubectl label node k8s-node-1 topology.kubernetes.io/zone=us-east-1b
kubectl label node k8s-node-2 topology.kubernetes.io/zone=us-east-1c
