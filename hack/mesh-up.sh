#!/usr/bin/env bash

set -o errexit

REPO_ROOT=$(git rev-parse --show-toplevel)

# create mesh
kubectl apply -f ${REPO_ROOT}/appmesh/global.yaml
sleep 20

# create virtual nodes and virtual services
kubectl apply -f ${REPO_ROOT}/appmesh/
sleep 5

# deploy ingress and workloads
kubectl apply -f ${REPO_ROOT}/ingress/
kubectl apply -f ${REPO_ROOT}/workloads/