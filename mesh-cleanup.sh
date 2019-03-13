#!/usr/bin/env bash

set -x

MESH=global

echo "Deleting virtual services"
aws appmesh delete-virtual-service --mesh-name ${MESH} --virtual-service-name frontend.test.svc.cluster.local
aws appmesh delete-virtual-service --mesh-name ${MESH} --virtual-service-name backend.test.svc.cluster.local

echo "Deleting routes"
aws appmesh delete-route --mesh-name ${MESH} --route-name frontend-route --virtual-router-name frontend-router
aws appmesh delete-route --mesh-name ${MESH} --route-name backend-route --virtual-router-name backend-router

echo "Deleting virtual routers"
aws appmesh delete-virtual-router --mesh-name ${MESH} --virtual-router-name frontend-router
aws appmesh delete-virtual-router --mesh-name ${MESH} --virtual-router-name backend-router

echo "Deleting virtual nodes"
aws appmesh delete-virtual-node --mesh-name ${MESH} --virtual-node-name frontend
aws appmesh delete-virtual-node --mesh-name ${MESH} --virtual-node-name backend
aws appmesh delete-virtual-node --mesh-name ${MESH} --virtual-node-name backend-primary

echo "Deleting mesh"
aws appmesh delete-mesh --mesh-name ${MESH}

echo "Deleting CRs"
kubectl delete -f ./routing/
kubectl delete -f ./mesh/

echo "Deleting workloads"
kubectl delete -f ./workloads/

