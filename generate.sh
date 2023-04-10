
#!/bin/sh

total_apps=1000
total_resources=3

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


