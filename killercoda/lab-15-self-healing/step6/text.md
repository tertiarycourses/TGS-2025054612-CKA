# Step 6 — Cleanup

```bash
kubectl delete pod live-demo ready-demo
kubectl delete deploy rs-demo
kubectl -n kube-system delete ds log-agent
kubectl delete statefulset web-ss
kubectl delete svc web-headless
```
