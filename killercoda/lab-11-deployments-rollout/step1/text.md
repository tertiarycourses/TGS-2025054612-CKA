# Step 1 — Create the Deployment

```bash
kubectl create deployment web --image=nginx:1.25 --replicas=4
kubectl rollout status deploy/web
kubectl get pods -l app=web -o wide
```
