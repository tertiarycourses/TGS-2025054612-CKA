# Step 5 — Inspect Endpoints & EndpointSlices

```bash
kubectl get endpoints web-clusterip
kubectl get endpointslices -l kubernetes.io/service-name=web-clusterip
kubectl describe endpointslice -l kubernetes.io/service-name=web-clusterip
```

EndpointSlices are the modern, scalable replacement; the legacy `Endpoints` object still exists for compatibility.
