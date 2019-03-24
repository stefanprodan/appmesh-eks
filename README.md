# EKS App Mesh

The App Mesh integration with Kubernetes is made out of the following components:

* Kubernetes custom resources
    * `mesh.appmesh.k8s.aws` defines a logical boundary for network traffic between the services 
    * `virtualnode.appmesh.k8s.aws` defines a logical pointer to a Kubernetes workload
    * `virtualservice.appmesh.k8s.aws` defines the routing rules for a workload inside the mesh
* CRD controller - keeps the custom resources in sync with the App Mesh control plane
* Admission controller - injects the Envoy sidecar and assigns Kubernetes pods to App Mesh virtual nodes

> Note that this is not an official AWS guide

### Prerequisites

* AWS CLI (default region us-west-2)
* openssl
* kubectl
* curl

### Install

Install eksctl:

```bash
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl
```

Create an EKS cluster:

```bash
eksctl create cluster --name=appmesh \
--region=us-west-2 \
--appmesh-access
```

Install the App Mesh components:

```bash
curl -fsSL https://git.io/get-app-mesh-eks.sh | bash -
```

Installer tasks:

* create the `appmesh-system` namespace
* generate a certificate signed by Kubernetes CA
* register the App Mesh mutating webhook
* deploy the App Mesh webhook
* deploy the App Mesh CRDs
* deploy the App Mesh controller
* create a mesh called `global` in the `appmesh-system` namespace



