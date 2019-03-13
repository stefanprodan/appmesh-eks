# appmesh-demo

```bash
# create appmesh-system and test namespaces
kubectl apply -f ./namespaces

# deploy the AppMesh operator
kubectl apply -f ./operator

# create a test mesh
kubectl apply -f ./mesh

# create virtual nodes and services
kubectl apply -f ./routing

# deploy frontend and backend workloads in the mesh
kubectl apply -f ./workloads

# deploy podinfo outside the mesh
kubectl apply -f ./podinfo
```


