# Step 5 — Roll back

```bash
kubectl rollout undo deploy/web
kubectl rollout status deploy/web
kubectl rollout history deploy/web
```

Go back to a specific revision:

```bash
kubectl rollout undo deploy/web --to-revision=1
```
