# Step 4 — Cause a bad rollout

```bash
kubectl set image deploy/web nginx=nginx:doesnotexist
kubectl rollout status deploy/web --timeout=30s
kubectl get pods -l app=web
```

New replicas stay `ImagePullBackOff`; old replicas keep serving.
