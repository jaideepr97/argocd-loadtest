
#!/bin/sh
total_apps=40

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
