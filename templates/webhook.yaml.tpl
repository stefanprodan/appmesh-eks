---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-app-mesh-inject-sa
  namespace: appmesh-system
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: aws-app-mesh-inject-cr
rules:
  - apiGroups: ["*"]
    resources: ["replicasets"]
    verbs: ["get"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: aws-app-mesh-inject-binding
subjects:
  - kind: ServiceAccount
    name: aws-app-mesh-inject-sa
    namespace: appmesh-system
    apiGroup: ""
roleRef:
  kind: ClusterRole
  name: aws-app-mesh-inject-cr
  apiGroup: ""
---
apiVersion: v1
kind: Service
metadata:
  name: aws-app-mesh-inject
  namespace: appmesh-system
  labels:
    app: aws-app-mesh-inject
spec:
  ports:
    - name: webhook
      port: 443
      targetPort: 8080
  selector:
    app: aws-app-mesh-inject
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aws-app-mesh-inject
  namespace: appmesh-system
  labels:
    app: aws-app-mesh-inject
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aws-app-mesh-inject
  template:
    metadata:
      labels:
        app: aws-app-mesh-inject
    spec:
      serviceAccountName: aws-app-mesh-inject-sa
      containers:
        - name: webhook
          image: $WEBHOOK_IMAGE
          env:
            - name: APPMESH_NAME
              value: $APPMESH_NAME
            - name: APPMESH_LOG_LEVEL
              value: $APPMESH_LOG_LEVEL
          imagePullPolicy: IfNotPresent
          command:
            - ./appmeshinject
            - -sidecar-image=$SIDECAR_IMAGE
            - -init-image=$INIT_IMAGE
          resources:
            requests:
              memory: 64Mi
              cpu: 10m
          volumeMounts:
            - name: webhook-certs
              mountPath: /etc/webhook/certs
              readOnly: true
          readinessProbe:
            httpGet:
              path: /healthz
              port: 8080
              scheme: HTTPS
            initialDelaySeconds: 1
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8080
              scheme: HTTPS
            initialDelaySeconds: 5
            periodSeconds: 10
          securityContext:
            readOnlyRootFilesystem: true
      volumes:
        - name: webhook-certs
          secret:
            secretName: aws-app-mesh-inject
