# Step 6 — Pause and resume

```bash
kubectl rollout pause deploy/web
kubectl set image deploy/web nginx=nginx:1.27
kubectl set resources deploy/web --limits=cpu=200m,memory=256Mi
kubectl rollout resume deploy/web
kubectl rollout status deploy/web
```

Pause batches multiple changes into one rollout.
