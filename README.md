# appmesh-demo

Install eksctl:

```bash
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl
```

Create an EKS cluster:

```bash
eksctl create cluster --name=appmesh --region=us-west-2
```

Create an [IAM policy](https://docs.aws.amazon.com/app-mesh/latest/userguide/MESH_IAM_user_policies.html)
for AppMesh and attache it to the EKS node instance role:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "appmesh:*"
            ],
            "Resource": "*"
        }
    ]
}
```

Create the `appmesh-system` namespace and deploy the AppMesh operator:

```bash
# create appmesh-system and test namespaces
kubectl apply -f ./namespaces

# deploy the AppMesh operator
kubectl apply -f ./operator
```

Create a mesh called global in the `appmesh-system` namespace:

```bash
kubectl apply -f ./mesh
```

Verify that the global mesh is active:

```bash
kubectl -n appmesh-system describe mesh

Status:
  Mesh Condition:
    Status:                True
    Type:                  Active
```

Create virtual nodes and services:

```bash
kubectl apply -f ./routing
```

Verify that the virtual nodes were registered in AppMesh:

```bash
aws appmesh list-virtual-nodes --mesh-name=global
```

Verify that the routes were registered in AppMesh:

```bash
aws appmesh describe-route --route-name=backend-route \
    --mesh-name=global \
    --virtual-router-name=backend-router

aws appmesh describe-route --route-name=frontend-route \
    --mesh-name=global \
    --virtual-router-name=frontend-router
```

Deploy the ingress, frontend and backend workloads:

```bash
kubectl apply -f ./ingress
kubectl apply -f ./workloads
```

Find the load balancer address:

```bash
kubectl -n test describe svc/ingress | grep Ingress

LoadBalancer Ingress:     yyy-xx.us-west-2.elb.amazonaws.com
```

Verify that the ingress -> frontend -> backend mesh communication is working:

```bash
curl -vd 'test' http://yyy-xx.us-west-2.elb.amazonaws.com/api/echo

< HTTP/1.1 202 Accepted
< server: envoy
< x-envoy-upstream-service-time: 5
```




