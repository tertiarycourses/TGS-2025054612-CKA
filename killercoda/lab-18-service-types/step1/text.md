# Step 1 — Deploy a workload

```bash
kubectl create deployment web --image=nginx --replicas=3
kubectl rollout status deploy/web
kubectl get pods -l app=web -o wide
```
