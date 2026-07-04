# Step 2 — Baseline: everything allowed

```bash
kubectl -n netpol exec client-ok  -- curl -s -o /dev/null -w "%{http_code}\n" http://server
kubectl -n netpol exec client-bad -- curl -s -o /dev/null -w "%{http_code}\n" http://server
```

Both should print `200`.
