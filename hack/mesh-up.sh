#!/usr/bin/env bash

set -o errexit

REPO_ROOT=$(git rev-parse --show-toplevel)

kubectl apply -f ${REPO_ROOT}/mesh/
sleep 20
kubectl apply -f ${REPO_ROOT}/routing/
sleep 5
kubectl apply -f ${REPO_ROOT}/ingress/
kubectl apply -f ${REPO_ROOT}/workloads/