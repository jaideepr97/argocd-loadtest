#!/bin/sh

total_apps=1000
total_resources=3

function generate() {
  generateCMs
  generateDeployments
  generateSecrets
}

function generateCMs() {
  for a in $(seq 1 $total_apps); do
  mkdir -p "test-app-$a"
  for b in $(seq 1 $total_resources); do
    cat >test-app-$a/configmap-$b.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: cm-dir$a-num$b
data:
  test.json: |
   {
      "maxThreadCount": 10,
      "trackerConfigs": [{
              "url": "https://example1.com/",
              "username": "username",
              "password": "password",
              "defaultLimit": 1
          },
          {
              "url": "https://example2.com/",
              "username": "username",
              "password": "password",
              "defaultLimit": 1
          }
      ],
      "repoConfigs": [{
          "url": "https://github.com/",
          "username": "username",
          "password": "password",
          "type": "GITHUB"
      }],
      "streamConfigs": [{
          "url": "https://example.com/master.json",
          "type": "JSON"
      }]
    }
EOF
  done
done
}

function generateDeployments() {
  for a in $(seq 1 $total_apps); do
  cat >test-app-$a/deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment-$a
  labels:
    app: web
spec:
  selector:
    matchLabels:
      app: web
  replicas: 5
  strategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
       —name: nginx
          image: nginx
          ports:
           —containerPort: 80
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 5
EOF
done 
}

function generateSecrets() {
  for a in $(seq 1 $total_apps); do
  cat >test-app-$a/secret.yaml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: sio-secret-$a
type: kubernetes.io/scaleio
data:
  username: YWRtaW4=
  password: c0NhbGVpbzEyMw==
EOF
done 
}

function apply() {
applyNamespaces
applyApps

}

function applyNamespaces() {
for i in $(seq 1 $total_apps); do 
cat << EOF | kubectl apply -f -    
apiVersion: v1
kind: Namespace
metadata:
  name: test-ns-$i
  labels:
    argocd.argoproj.io/managed-by: argocd
EOF
done
}

function applyApps() {
  for a in $(seq 1 $total_apps); do
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: test-app-$a
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/jaideepr97/argocd-loadtest.git
    targetRevision: HEAD
    path: test-app-$a
  destination:
    server: https://kubernetes.default.svc
    namespace: test-ns-$a
EOF
done

}

function delete() {
for a in $(seq 1 $total_apps); do
	kubectl delete ns test-ns-$a 
	kubectl delete application test-app-$a -n argocd
done
}

function delete_folders() {
	rm -rf test-app-*
}

while getopts ":gadf" option; do
  case $option in
    g) 
      echo "generating"
      generate
      exit;;
    a)
      echo "applying"
      apply
      exit;;
    d)
      echo "deleting"
      delete
      exit;;
    f)
      echo "deleting folders"
      delete_folders
      exit;;
  esac
done