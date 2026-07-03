# Step 2 — Inspect the strategy

```bash
kubectl get deploy web -o yaml | grep -A5 strategy
```

Default is `RollingUpdate` with `maxSurge: 25%` and `maxUnavailable: 25%`.
