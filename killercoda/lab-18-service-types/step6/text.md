# Step 6 — Cleanup

```bash
kubectl delete svc web-clusterip web-nodeport web-lb
kubectl delete deploy web
# Optional: kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
```
