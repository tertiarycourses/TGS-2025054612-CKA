# Step 3 — Perform a rolling update

```bash
kubectl set image deploy/web nginx=nginx:1.26 --record
kubectl rollout status deploy/web
kubectl rollout history deploy/web
```

Watch in another shell:

```bash
kubectl get pods -l app=web -w
```

You'll see new pods come up while old ones are still serving — that's the surge.
