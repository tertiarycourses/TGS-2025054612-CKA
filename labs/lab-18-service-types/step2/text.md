# Step 2 — ClusterIP (default)

```bash
kubectl expose deploy web --port=80 --name=web-clusterip
kubectl get svc web-clusterip
kubectl get endpoints web-clusterip
CIP=$(kubectl get svc web-clusterip -o jsonpath='{.spec.clusterIP}')
kubectl run probe --image=busybox --rm -it --restart=Never -- wget -qO- $CIP | head -5
```

ClusterIP is in-cluster only. The Endpoints object lists the three pod IPs that kube-proxy load-balances over.
