# Step 2 — kubectl top

```bash
kubectl top nodes
kubectl top pods -A
kubectl top pods -A --sort-by=cpu | head
kubectl top pods -A --sort-by=memory | head
```

`kubectl top` reads from the Metrics API served by metrics-server.
