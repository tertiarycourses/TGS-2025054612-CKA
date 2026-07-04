# Step 6 — Render without installing

```bash
helm template web bitnami/nginx -f values.yaml | head -50
```

`helm template` is the GitOps-friendly alternative — it just renders YAML, no Tiller-style state in-cluster.
