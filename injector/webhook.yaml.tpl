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
      caBundle: "CA_BUNDLE"
    rules:
      - operations: ["CREATE","UPDATE"]
        apiGroups: [""]
        apiVersions: ["v1"]
        resources: ["pods"]
    failurePolicy: Ignore
    namespaceSelector:
      matchLabels:
        appmesh.k8s.aws/sidecarInjectorWebhook: enabled
