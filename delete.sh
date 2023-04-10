
#!/bin/sh

total_apps=40

for a in $(seq 1 $total_apps); do
	kubectl delete ns test-ns-$a 
	kubectl delete application test-app-$a -n argocd
done
