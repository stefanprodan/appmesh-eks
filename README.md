# AppMesh EKS

This guide walks you through setting up AppMesh on Amazon Elastic Container Service for Kubernetes (EKS).

Prerequisites:

* AWS CLI (default region us-west-2)
* openssl
* kubectl
* homebrew

### Create a Kubernetes cluster with eksctl

In order to create an EKS cluster you can use [eksctl](https://eksctl.io).
eksctl is an open source command-line utility made by Weaveworks in collaboration with Amazon, 
it's written in Go and is based on EKS CloudFormation templates.

On MacOS you can install eksctl with Homebrew::

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

Install Helm CLI with Homebrew:

```bash
brew install kubernetes-helm
```

Create a service account and a cluster role binding for Tiller:

```bash
kubectl -n kube-system create sa tiller

kubectl create clusterrolebinding tiller-cluster-rule \
    --clusterrole=cluster-admin \
    --serviceaccount=kube-system:tiller 
```

Deploy Tiller on EKS:

```bash
helm init --service-account tiller
```

### Install AppMesh Kubernetes controllers

Create the `appmesh-system` namespace:

```bash
kubectl apply -f ./namespaces/appmesh-system.yaml
```

Deploy the AppMesh Kubernetes CRDs and operator:

```bash
kubectl apply -f ./operator/
```

Deploy Prometheus in the `appmesh-system` namespace:

```bash
kubectl apply -f ./prometheus
```

Install the AppMesh sidecar injector in the `appmesh-system` namespace:

```bash
./injector/install.sh
```

The above script generates a certificate signed by Kubernetes CA,
registers the AppMesh mutating webhook and deploys the injector.

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

### Demo

Create a test namespace with sidecar injector enabled:

```bash
kubectl apply -f ./namespaces/test.yaml
```

Create virtual nodes and services:

```bash
kubectl apply -f ./routing
```

Verify that the virtual nodes were registered in AppMesh:

```bash
aws appmesh list-virtual-nodes --mesh-name=global | jq '.virtualNodes[].virtualNodeName'
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




