#!/usr/bin/env bash

set -x

REPO_ROOT=$(git rev-parse --show-toplevel)
MESH=global

echo "Deleting virtual services"
aws appmesh delete-virtual-service --mesh-name ${MESH} --virtual-service-name frontend.test

echo "Deleting routes"
aws appmesh delete-route --mesh-name ${MESH} --route-name frontend-test-route --virtual-router-name frontend-test-router

echo "Deleting virtual routers"
aws appmesh delete-virtual-router --mesh-name ${MESH} --virtual-router-name frontend-test-router

echo "Deleting virtual nodes"
aws appmesh delete-virtual-node --mesh-name ${MESH} --virtual-node-name frontend-test
aws appmesh delete-virtual-node --mesh-name ${MESH} --virtual-node-name frontend-primary-test
aws appmesh delete-virtual-node --mesh-name ${MESH} --virtual-node-name frontend-canary-test

echo "Listing mesh objects"
aws appmesh list-virtual-services --mesh-name ${MESH}
aws appmesh list-virtual-routers --mesh-name ${MESH}
aws appmesh list-virtual-nodes --mesh-name ${MESH}