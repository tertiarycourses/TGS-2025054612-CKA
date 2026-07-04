# Step 2 — Readiness probe

```bash
kubectl run ready-demo --image=nginx \
  --overrides='{"spec":{"containers":[{"name":"ready-demo","image":"nginx","readinessProbe":{"httpGet":{"path":"/","port":80},"initialDelaySeconds":3,"periodSeconds":3}}]}}'
kubectl get pod ready-demo -w
```

`READY 0/1` until the probe passes, then `1/1`. Readiness gates Service endpoints — failing pods are removed from the load balancer but **not** restarted.
