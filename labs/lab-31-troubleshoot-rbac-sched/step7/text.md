# Step 7 — Pending due to nodeSelector

```bash
kubectl -n app run picky --image=nginx \
  --overrides='{"spec":{"nodeSelector":{"zone":"never"}}}'
kubectl -n app describe pod picky | tail -10
```

`didn't match Pod's node affinity/selector`. Fix the label or the selector.
