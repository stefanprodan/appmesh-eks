#!/bin/bash

set -e

echo "checking prerequisites: openssl, kubectl, jq and curl"

if [ ! -x "$(command -v openssl)" ]; then
    echo "openssl not found"
    exit 1
fi

if [ ! -x "$(command -v kubectl)" ]; then
    echo "kubectl not found"
    exit 1
fi


if [ ! -x "$(command -v jq)" ]; then
    echo "curl not found"
    exit 1
fi

if [ ! -x "$(command -v curl)" ]; then
    echo "curl not found"
    exit 1
fi

tmpdir=$(mktemp -d)

REPO_URL=https://raw.githubusercontent.com/stefanprodan/appmesh-eks/master/templates

echo "downloading templates in tmpdir ${tmpdir}"
curl -sS ${REPO_URL}/namespace.yaml -o ${tmpdir}/namespace.yaml
curl -sS ${REPO_URL}/webhook.yaml.tpl -o ${tmpdir}/webhook.yaml.tpl
curl -sS ${REPO_URL}/controller.yaml.tpl -o ${tmpdir}/controller.yaml.tpl
curl -sS ${REPO_URL}/mesh.yaml.tpl -o ${tmpdir}/mesh.yaml.tpl

export CONTROLLER_IMAGE=602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon/app-mesh-controller:v0.1.0
export WEBHOOK_IMAGE=602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon/aws-app-mesh-inject:v0.1.0
export SIDECAR_IMAGE=111345817488.dkr.ecr.us-west-2.amazonaws.com/aws-appmesh-envoy:v1.9.0.0-prod
export INIT_IMAGE=111345817488.dkr.ecr.us-west-2.amazonaws.com/aws-appmesh-proxy-route-manager:latest
export APPMESH_NAME=global
export APPMESH_LOG_LEVEL=debug

echo "processing templates"
eval "cat <<EOF
$(<${tmpdir}/webhook.yaml.tpl)
EOF
" > ${tmpdir}/webhook.yaml

eval "cat <<EOF
$(<${tmpdir}/mesh.yaml.tpl)
EOF
" > ${tmpdir}/mesh.yaml

eval "cat <<EOF
$(<${tmpdir}/controller.yaml.tpl)
EOF
" > ${tmpdir}/controller.yaml

echo "creating appmesh-system namespace"
kubectl apply -f ${tmpdir}/namespace.yaml

service=aws-app-mesh-inject
secret=aws-app-mesh-inject
namespace=appmesh-system
csrName=${service}.${namespace}
echo "creating certs in tmpdir ${tmpdir} "

cat <<EOF >> ${tmpdir}/csr.conf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${service}
DNS.2 = ${service}.${namespace}
DNS.3 = ${service}.${namespace}.svc
EOF

openssl genrsa -out ${tmpdir}/server-key.pem 2048
openssl req -new -key ${tmpdir}/server-key.pem -subj "/CN=${service}.${namespace}.svc" -out ${tmpdir}/server.csr -config ${tmpdir}/csr.conf

# clean-up any previously created CSR for our service. Ignore errors if not present.
kubectl delete csr ${csrName} 2>/dev/null || true

# create  server cert/key CSR and  send to k8s API
cat <<EOF | kubectl create -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: ${csrName}
spec:
  groups:
  - system:authenticated
  request: $(cat ${tmpdir}/server.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

# verify CSR has been created
while true; do
    kubectl get csr ${csrName}
    if [ "$?" -eq 0 ]; then
        break
    fi
done

# approve and fetch the signed certificate
kubectl certificate approve ${csrName}
# verify certificate has been signed
for x in $(seq 10); do
    serverCert=$(kubectl get csr ${csrName} -o jsonpath='{.status.certificate}')
    if [[ ${serverCert} != '' ]]; then
        break
    fi
    sleep 1
done
if [[ ${serverCert} == '' ]]; then
    echo "ERROR: After approving csr ${csrName}, the signed certificate did not appear on the resource. Giving up after 10 attempts." >&2
    exit 1
fi
echo ${serverCert} | openssl base64 -d -A -out ${tmpdir}/server-cert.pem

# create the secret with CA cert and server cert/key
kubectl create secret generic ${secret} \
        --from-file=key.pem=${tmpdir}/server-key.pem \
        --from-file=cert.pem=${tmpdir}/server-cert.pem \
        --dry-run -o yaml |
    kubectl -n ${namespace} apply -f -

# get API server ca bundle
export CA_BUNDLE=$(kubectl get configmap -n kube-system extension-apiserver-authentication -o=jsonpath='{.data.client-ca-file}' | base64 | tr -d '\n')

if [[ -z ${CA_BUNDLE} ]]; then
	export CA_BUNDLE=$(kubectl config view --raw -o json --minify | jq -r '.clusters[0].cluster."certificate-authority-data"' | tr -d '"')
fi

cat <<EOF | kubectl apply -f -
apiVersion: admissionregistration.k8s.io/v1beta1
kind: MutatingWebhookConfiguration
metadata:
  name: aws-app-mesh-inject
webhooks:
  - name: aws-app-mesh-inject.aws.amazon.com
    clientConfig:
      service:
        name: aws-app-mesh-inject
        namespace: appmesh-system
        path: "/"
      caBundle: "${CA_BUNDLE}"
    rules:
      - operations: ["CREATE","UPDATE"]
        apiGroups: [""]
        apiVersions: ["v1"]
        resources: ["pods"]
    failurePolicy: Ignore
    namespaceSelector:
      matchLabels:
        appmesh.k8s.aws/sidecarInjectorWebhook: enabled
EOF

echo "installing aws-app-mesh-inject"
kubectl apply -f ${tmpdir}/webhook.yaml

echo "waiting for aws-app-mesh-inject to start"
kubectl -n appmesh-system rollout status deployment aws-app-mesh-inject

echo "installing aws-app-mesh-controller"
kubectl apply -f ${tmpdir}/controller.yaml

echo "waiting for aws-app-mesh-controller to start"
kubectl -n appmesh-system rollout status deployment aws-app-mesh-controller

echo "creating global mesh"
kubectl apply -f ${tmpdir}/mesh.yaml

echo "App Mesh installed successfully"
