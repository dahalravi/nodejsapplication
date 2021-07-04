 how to develop a Node.js/MongoDB application using Docker Compose
 
 Steps 
1) git clone https://github.com/dahalravi/nodejsapplication.git -b master node_project

2) Navigate to the node_project directory:
    cd node_project
3) The file in our cloned repository that specifies database connection information is called db.js and update the connection string 
     vi db.js
     
4) Build the image with docker build locally 
     docker build -t your_dockerhub_username/node-replicas .
     
5) It will take a minute or two to build the image. Once it is complete, check your images
     docker images 
6) Next,  prerequisites: push to  local repository and use it 

Note:- Create a secrete file for the DB as per standards and name it as secret.yaml 

sample 

apiVersion: v1
kind: Secret
metadata:
  name: mongo-secret
data:
  user: your_encoded_username
  password: your_encoded_password
  
  7) create the secret file for DB using kubectl create -f secret.yaml
  8) Configuring the MongoDB Helm Chart and Creating a Deployment
  9) use the storage class available in the cluster 
      kubectl get storageclass
  10) udpate mongodb-values.yaml with storage class and secret file 
  
  sample 
  
  replicas: 3
port: 27017
replicaSetName: db
podDisruptionBudget: {}
auth:
  enabled: true
  existingKeySecret: keyfilesecret
  existingAdminSecret: mongo-secret
imagePullSecrets: []
installImage:
  repository: dahalravi/mongodb-install
  tag: 0.7
  pullPolicy: Always
copyConfigImage:
  repository: busybox
  tag: 1.29.3
  pullPolicy: Always
image:
  repository: mongo
  tag: 4.1.9
  pullPolicy: Always
extraVars: {}
metrics:
  enabled: false
  image:
    repository: dahalravi/mongodb-exporter
    tag: 0.6.1
    pullPolicy: IfNotPresent
  port: 9216
  path: /metrics
  socketTimeout: 3s
  syncTimeout: 1m
  prometheusServiceDiscovery: true
  resources: {}
podAnnotations: {}
securityContext:
  enabled: true
  runAsUser: 999
  fsGroup: 999
  runAsNonRoot: true
init:
  resources: {}
  timeout: 900
resources: {}
nodeSelector: {}
affinity: {}
tolerations: []
extraLabels: {}
persistentVolume:
  enabled: true
  #storageClass: "-"
  accessModes:
    - ReadWriteOnce
  size: 1Gi
  annotations: {}
serviceAnnotations: {}
terminationGracePeriodSeconds: 30
tls:
  enabled: false
configmap: {}
readinessProbe:
  initialDelaySeconds: 5
  timeoutSeconds: 1
  failureThreshold: 3
  periodSeconds: 10
  successThreshold: 1
livenessProbe:
  initialDelaySeconds: 30
  timeoutSeconds: 5
  failureThreshold: 3
  periodSeconds: 10
  successThreshold: 1
  
11) update the stable repo with the helm repo update command:
    helm repo update
12) install the chart with the following command:
      helm install --name mongo -f mongodb-values.yaml stable/mongodb-replicaset
13) check on the creation of your Pods and resources  with the following command:
       kubectl get pods
       kubectl get statefulset
       kubectl get svc
       
 14) Creating a Custom Application Chart and Configuring Parameters
 15) helm create nodeapp
 
 
 This will create a directory called nodeapp in your ~/node_project folder with the following resources:

A Chart.yaml file with basic information about your chart.
A values.yaml file that allows you to set specific parameter values, as you did with your MongoDB deployment.
A .helmignore file with file and directory patterns that will be ignored when packaging charts.
A templates/ directory with the template files that will generate Kubernetes manifests.
A templates/tests/ directory for test files.
A charts/ directory for any charts that this chart depends on.
 
16) Configure the following values in the values.yaml file:
   # Default values for nodeapp.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

replicaCount: 3

image:
  repository: dahalravi/node-replicas
  tag: latest
  pullPolicy: IfNotPresent

nameOverride: ""
fullnameOverride: ""

service:
  type: LoadBalancer
  port: 80
  targetPort: 8080
  
17) open a secret.yaml file in the nodeapp/templates directory and update the values 

apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}-auth
data:
  MONGO_USERNAME: your_encoded_username
  MONGO_PASSWORD: your_encoded_password
  
18)  open a file to create a ConfigMap for your application:
    apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-config
data:
  MONGO_HOSTNAME: "mongo-mongodb-replicaset-0.mongo-mongodb-replicaset.default.svc.cluster.local,mongo-mongodb-replicaset-1.mongo-mongodb-replicaset.default.svc.cluster.local,mongo-mongodb-replicaset-2.mongo-mongodb-replicaset.default.svc.cluster.local"
  MONGO_PORT: "27017"
  MONGO_DB: "sharkinfo"
  MONGO_REPLICASET: "db"
  
18) Integrating Environment Variables into Your Helm Deployment like Dev and SIT 

19) vi nodeapp/templates/deployment.yaml
20) first add an env key to your application container specifications, below the imagePullPolicy key and above ports:
      apiVersion: apps/v1
kind: Deployment
metadata:
...
  spec:
    containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        env:
        - name: MONGO_USERNAME
          valueFrom:
            secretKeyRef:
              key: MONGO_USERNAME
              name: {{ .Release.Name }}-auth
        - name: MONGO_PASSWORD
          valueFrom:
            secretKeyRef:
              key: MONGO_PASSWORD
              name: {{ .Release.Name }}-auth
        - name: MONGO_HOSTNAME
          valueFrom:
            configMapKeyRef:
              key: MONGO_HOSTNAME
              name: {{ .Release.Name }}-config
        - name: MONGO_PORT
          valueFrom:
            configMapKeyRef:
              key: MONGO_PORT
              name: {{ .Release.Name }}-config
        - name: MONGO_DB
          valueFrom:
            configMapKeyRef:
              key: MONGO_DB
              name: {{ .Release.Name }}-config
        - name: MONGO_REPLICASET
          valueFrom:
            configMapKeyRef:
              key: MONGO_REPLICASET
              name: {{ .Release.Name }}-config
        
 21) Finally, install the application 
     helm install --name nodejs ./nodeapp
     
 22) Verify pods and resoruces 

kubectl get pods
kubectl get svc






