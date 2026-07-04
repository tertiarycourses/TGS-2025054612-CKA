# Step 4 — Container-level stats via cAdvisor (reference)

```bash
NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
kubectl get --raw "/api/v1/nodes/$NODE/proxy/stats/summary" | head -50
```

This raw endpoint feeds metrics-server, Prometheus, and any node-level monitoring agent.
