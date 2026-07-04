# Step 5 — Update propagation

```bash
kubectl edit configmap app-properties   # change cache.ttl=300 to 60
kubectl exec file-demo -- cat /etc/cfg/app.properties
```

Mounted ConfigMaps update **in place** after ~30–60 s — environment variables do **not**. To pick up env var changes you must restart the pod (`kubectl rollout restart deploy/...`).
