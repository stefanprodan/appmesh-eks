#!/usr/bin/env bash

set -x

kubectl apply -f ./mesh/
sleep 20
kubectl apply -f ./routing/
sleep 5
kubectl apply -f ./ingress/
kubectl apply -f ./workloads/