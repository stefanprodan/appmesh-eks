#!/usr/bin/env bash

set -x

REPO_ROOT=$(git rev-parse --show-toplevel)
MESH=global

echo "Deleting virtual services"
aws appmesh delete-virtual-service --mesh-name ${MESH} --virtual-service-name frontend.test
aws appmesh delete-virtual-service --mesh-name ${MESH} --virtual-service-name backend.test

echo "Deleting routes"
aws appmesh delete-route --mesh-name ${MESH} --route-name frontend-route-test --virtual-router-name frontend-router-test
aws appmesh delete-route --mesh-name ${MESH} --route-name backend-route-test --virtual-router-name backend-router-test

echo "Deleting virtual routers"
aws appmesh delete-virtual-router --mesh-name ${MESH} --virtual-router-name frontend-router-test
aws appmesh delete-virtual-router --mesh-name ${MESH} --virtual-router-name backend-router-test

echo "Deleting virtual nodes"
aws appmesh delete-virtual-node --mesh-name ${MESH} --virtual-node-name ingress-test
aws appmesh delete-virtual-node --mesh-name ${MESH} --virtual-node-name frontend-test
aws appmesh delete-virtual-node --mesh-name ${MESH} --virtual-node-name backend-test

echo "Deleting mesh"
aws appmesh delete-mesh --mesh-name ${MESH}

echo "Deleting CRs"
kubectl delete -f ${REPO_ROOT}/appmesh/

echo "Deleting ingress and workloads"
kubectl delete -f ${REPO_ROOT}/ingress/
kubectl delete -f ${REPO_ROOT}/workloads/
