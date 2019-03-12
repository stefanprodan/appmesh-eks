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

### Operator bugs

If the mesh is in a different namespace the virtual services will error out:

```
ERROR: logging before flag.Parse: E0312 16:37:52.233451       1 controller.go:370] error syncing 'test/backend.test.svc.cluster.local': mesh test for virtual service backend.test.svc.cluster.local does not exist
ERROR: logging before flag.Parse: E0312 16:37:52.233472       1 controller.go:370] error syncing 'test/frontend.test.svc.cluster.local': mesh test for virtual service frontend.test.svc.cluster.local does not exist
I0312 16:37:52.235494       1 controller.go:268] Virtual Node Updated
ERROR: logging before flag.Parse: E0312 16:37:52.235542       1 controller.go:370] error syncing 'test/frontend': mesh test for virtual node frontend does not exist
```

Mesh DNS doesn't work for short names:

```
kubectl -n test exec -it frontend-7586b46f8b-fj8q6 sh


curl -v backend:9898
HTTP/1.1 404 Not Found

curl -v backend.test:9898
HTTP/1.1 404 Not Found

curl -v backend.test.svc.cluster.local:9898
HTTP/1.1 200 OK
```

Kubernetes DNS does not work:

```bash
kubectl -n test exec -it frontend-7586b46f8b-fj8q6 sh

curl -v podinfo.test.svc.cluster.local:9898
HTTP/1.1 404 Not Found
```

Egress TLS is broken:

```
curl -v https://app.istio.weavedx.com/

LibreSSL SSL_connect: SSL_ERROR_SYSCALL in connection to app.istio.weavedx.com:443 
```

Klog is not initialised correctly:

```
ERROR: logging before flag.Parse:
``` 

When creating a mesh the workers will enter a race condition:

```
I0312 16:45:27.322232       1 controller.go:208] Mesh Added
I0312 16:45:27.333689       1 controller.go:244] Mesh Updated
I0312 16:45:27.420073       1 mesh.go:57] Discovered mesh test
ERROR: logging before flag.Parse: E0312 16:45:27.423631       1 controller.go:370] error syncing 'test/test': error updating mesh status: Operation cannot be fulfilled on meshes.appmesh.k8s.aws "test": the object has been modified; please apply your changes to the latest version and try again
```

