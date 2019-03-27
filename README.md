# App Mesh installer for EKS

The App Mesh integration with Kubernetes is made out of the following components:

* Kubernetes custom resources
    * `mesh.appmesh.k8s.aws` defines a logical boundary for network traffic between the services 
    * `virtualnode.appmesh.k8s.aws` defines a logical pointer to a Kubernetes workload
    * `virtualservice.appmesh.k8s.aws` defines the routing rules for a workload inside the mesh
* [CRD controller](https://github.com/aws/aws-app-mesh-controller-for-k8s) - keeps the custom resources in sync with the App Mesh control plane
* [Admission controller](https://github.com/aws/aws-app-mesh-inject) - injects the Envoy sidecar and assigns Kubernetes pods to App Mesh virtual nodes

App Mesh add-ons:

* [Flagger](https://github.com/weaveworks/flagger) - progressive delivery operator (automated canary deployments and A/B testing)
* [Prometheus](https://github.com/prometheus/prometheus) - monitoring system and time series database

### EKS

Install [eksctl](https://github.com/weaveworks/eksctl):

```bash
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl
```

Create an EKS cluster with the App Mesh IAM role:

```bash
eksctl create cluster --name=appmesh \
--nodes=2 \
--node-type=m5.xlarge \
--region=us-west-2 \
--appmesh-access
```

### App Mesh

Install the App Mesh components (requires openssl and jq):

```bash
curl -fsSL https://git.io/get-app-mesh-eks.sh | bash -
```

The installer script will do the following:

* creates the `appmesh-system` namespace
* generates a certificate signed by Kubernetes CA
* registers the App Mesh mutating webhook
* deploys the App Mesh webhook in `appmesh-system` namespace
* deploys the App Mesh CRDs
* deploys the App Mesh controller `appmesh-system` namespace
* creates a mesh called `global`

### App Mesh Add-ons

* [Install Flagger and Prometheus on EKS and App Mesh](https://docs.flagger.app/install/flagger-install-on-eks-appmesh)
* [App Mesh automated canary deployments](https://docs.flagger.app/usage/appmesh-progressive-delivery)

> Note that this is not an official AWS installer


