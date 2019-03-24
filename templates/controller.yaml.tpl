---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: meshes.appmesh.k8s.aws
spec:
  group: appmesh.k8s.aws
  versions:
    - name: v1alpha1
      served: true
      storage: true
  version: v1alpha1
  scope: Namespaced
  names:
    plural: meshes
    singular: mesh
    kind: Mesh
    categories:
      - all
      - appmesh
  subresources:
    status: {}
  validation:
    openAPIV3Schema:
      required:
        - spec
      properties:
        spec:
          properties:
            serviceDiscoveryType:
              type: string
              enum:
                - dns
        status:
          properties:
            meshArn:
              type: string
            conditions:
              type: array
              items:
                type: object
                required:
                  - type
                properties:
                  type:
                    type: string
                    enum:
                      - MeshActive
                  status:
                    type: string
                    enum:
                      - "True"
                      - "False"
                      - Unknown
                  lastTransitionTime:
                    type: string
                  reason:
                    type: string
                  message:
                    type: string
---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: virtualnodes.appmesh.k8s.aws
spec:
  group: appmesh.k8s.aws
  versions:
    - name: v1alpha1
      served: true
      storage: true
  version: v1alpha1
  scope: Namespaced
  names:
    plural: virtualnodes
    singular: virtualnode
    kind: VirtualNode
    categories:
      - all
      - appmesh
  subresources:
    status: {}
  validation:
    openAPIV3Schema:
      required:
        - spec
      properties:
        spec:
          required:
            - meshName
          properties:
            meshName:
              type: string
            listeners:
              type: array
              items:
                type: object
                properties:
                  portMapping:
                    properties:
                      port:
                        type: integer
                      protocol:
                        type: string
                        enum:
                          - tcp
                          - http
                          - grpc
                          - http2
                          - https
            serviceDiscovery:
              type: object
              properties:
                cloudMap:
                  type: object
                  properties:
                    cloudMapServiceName:
                      type: string
                dns:
                  type: object
                  properties:
                    hostName:
                      type: string
            backends:
              type: array
              items:
                oneOf:
                  - type: object
                    properties:
                      backendService:
                        type: object
                        properties:
                          name:
                            type: string
        status:
          properties:
            meshArn:
              type: string
            virtualNodeArn:
              type: string
            cloudMapServiceArn:
              type: string
            queryParameters:
              type: string
            conditions:
              type: array
              items:
                type: object
                required:
                  - type
                properties:
                  type:
                    type: string
                    enum:
                      - VirtualNodeActive
                      - MeshMarkedForDeletion
                  status:
                    type: string
                    enum:
                      - "True"
                      - "False"
                      - Unknown
                  lastTransitionTime:
                    type: string
                  reason:
                    type: string
                  message:
                    type: string
---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: virtualservices.appmesh.k8s.aws
spec:
  group: appmesh.k8s.aws
  versions:
    - name: v1alpha1
      served: true
      storage: true
  version: v1alpha1
  scope: Namespaced
  names:
    plural: virtualservices
    singular: virtualservice
    kind: VirtualService
    categories:
      - all
      - appmesh
  subresources:
    status: {}
  validation:
    openAPIV3Schema:
      required:
        - spec
      properties:
        spec:
          properties:
            meshName:
              type: string
            virtualRouter:
              type: object
              properties:
                name:
                  type: string
            routes:
              type: array
              items:
                type: object
                properties:
                  http:
                    type: object
                    properties:
                      match:
                        type: object
                        properties:
                          prefix:
                            type: string
                      action:
                        type: object
                        properties:
                          weightedTargets:
                            type: array
                            items:
                              type: object
                              properties:
                                virtualNodeName:
                                  type: string
                                weight:
                                  type: integer
        status:
          properties:
            virtualServiceArn:
              type: string
            virtualRouterArn:
              type: string
            routeArns:
              type: array
              items:
                type: string
            conditions:
              type: array
              items:
                type: object
                required:
                  - type
                properties:
                  type:
                    type: string
                    enum:
                      - VirtualServiceActive
                      - VirtualRouterActive
                      - RoutesActive
                      - MeshMarkedForDeletion
                  status:
                    type: string
                    enum:
                      - "True"
                      - "False"
                      - Unknown
                  lastTransitionTime:
                    type: string
                  reason:
                    type: string
                  message:
                    type: string
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-mesh-sa
  namespace: appmesh-system
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: app-mesh-controller
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["*"]
  - apiGroups: ["appmesh.k8s.aws"]
    resources: ["meshes", "virtualnodes", "virtualservices", "meshes/status", "virtualnodes/status", "virtualservices/status"]
    verbs: ["*"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: app-mesh-controller-binding
subjects:
  - kind: ServiceAccount
    name: app-mesh-sa
    namespace: appmesh-system
    apiGroup: ""
roleRef:
  kind: ClusterRole
  name: app-mesh-controller
  apiGroup: ""
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aws-app-mesh-controller
  namespace: appmesh-system
  labels:
    app: aws-app-mesh-controller
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aws-app-mesh-controller
  template:
    metadata:
      labels:
        app: aws-app-mesh-controller
    spec:
      serviceAccountName: app-mesh-sa
      containers:
        - name: controller
          image: $CONTROLLER_IMAGE
          imagePullPolicy: IfNotPresent
          resources:
            requests:
              memory: 64Mi
              cpu: 10m
          ports:
            - containerPort: 10555
