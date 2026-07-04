# Step 3 — Events

```bash
kubectl get events --sort-by=.lastTimestamp -A | tail -20
kubectl get events --field-selector type=Warning -A
```

Events are the cluster's audit trail — ~1 hour retention by default.
