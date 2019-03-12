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

# deploy frontend and backend workloads
kubectl apply -f ./workloads
```

Exec into frontend and call the backend:

```bash
kubectl -n test exec -it frontend-xxx-xxx sh

~ $ curl backend:9898
curl: (7) Failed to connect to backend port 9898: Connection refused
~ $ curl backend.test.svc.cluster.local:9898
curl: (7) Failed to connect to backend.test.svc.cluster.local port 9898: Connection refused
```
