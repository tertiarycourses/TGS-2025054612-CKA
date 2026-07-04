# Step 7 — Aggregated ClusterRoles (reference)

Built-in roles like `view`, `edit`, `admin` are aggregated. Inspect:

```bash
kubectl describe clusterrole view | head -20
```
