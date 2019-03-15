# EKS App Mesh

This guide walks you through setting up App Mesh on Amazon Elastic Container Service for Kubernetes (EKS).

The App Mesh integration with Kubernetes is made out of the following components:

* Kubernetes custom resources
    * `mesh.appmesh.k8s.aws` defines a logical boundary for network traffic between the services 
    * `virtualnode.appmesh.k8s.aws` defines a logical pointer to a Kubernetes workload
    * `virtualservice.appmesh.k8s.aws` defines the routing rules for a workload inside the mesh
* CRD controller - keeps the custom resources in sync with the App Mesh control plane
* Admission controller - injects the Envoy sidecar and assigns Kubernetes pods to App Mesh virtual nodes
* Metrics server - Prometheus instance that collects and stores Envoy's metrics
* Ingress server - Envoy instance that exposes services outside the mesh

> Note that this is not an official AWS guide. The APIs are alpha and could change at any time.

Prerequisites:

* AWS CLI (default region us-west-2)
* openssl
* kubectl

### Create a Kubernetes cluster with eksctl

In order to create an EKS cluster you can use [eksctl](https://eksctl.io).
eksctl is an open source command-line utility made by Weaveworks in collaboration with Amazon, 
it's written in Go and is based on EKS CloudFormation templates.

On MacOS you can install eksctl with Homebrew:

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

### Install the App Mesh components

Create the `appmesh-system` namespace:

```bash
kubectl apply -f ./namespaces/appmesh-system.yaml
```

Deploy the App Mesh Kubernetes CRDs and controller:

```bash
kubectl apply -f ./operator/
```

Install the App Mesh sidecar injector in the `appmesh-system` namespace:

```bash
./injector/install.sh
```

The above script generates a certificate signed by Kubernetes CA,
registers the App Mesh mutating webhook and deploys the injector.

Deploy the metrics server in the `appmesh-system` namespace:

```bash
kubectl apply -f ./prometheus
```

Create a mesh called global in the `appmesh-system` namespace:

```bash
kubectl apply -f ./appmesh/global.yaml
```

Verify that the global mesh is active:

```bash
kubectl -n appmesh-system describe mesh

Status:
  Mesh Condition:
    Status:                True
    Type:                  Active
```

### Deploy demo workloads

![appmesh-ingress](https://raw.githubusercontent.com/stefanprodan/appmesh-eks/master/diagrams/appmesh-prometheus.png)

Create a test namespace with sidecar injector enabled:

```bash
kubectl apply -f ./namespaces/test.yaml
```

Create the for frontend and backend virtual nodes and virtual services:

```bash
kubectl apply -f ./appmesh/frontend.yaml
kubectl apply -f ./appmesh/backend.yaml
```

Verify that the virtual nodes were registered in App Mesh:

```bash
aws appmesh list-virtual-nodes --mesh-name=global | jq '.virtualNodes[].virtualNodeName'
```

Verify that the routes were registered in App Mesh:

```bash
aws appmesh describe-route --route-name=backend-route \
    --mesh-name=global \
    --virtual-router-name=backend-router

aws appmesh describe-route --route-name=frontend-route \
    --mesh-name=global \
    --virtual-router-name=frontend-router
```

Deploy the frontend and backend workloads:

```bash
kubectl apply -f ./workloads
```

### Setup the Envoy ingress

Create the ingress virtual node:

```bash
kubectl apply -f ./appmesh/ingress.yaml
```

Deploy the ingress and the load balancer service:

```bash
kubectl apply -f ./ingress
```

Find the ingress public address:

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



