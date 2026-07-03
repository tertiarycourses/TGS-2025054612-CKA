# Step 3 — Bind the Role to the ServiceAccount

```bash
kubectl -n rbac-demo create rolebinding viewer-binding \
  --role=pod-viewer \
  --serviceaccount=rbac-demo:viewer
```
