# Step 2 — Create a Role

```bash
kubectl -n rbac-demo create role pod-viewer \
  --verb=get,list,watch \
  --resource=pods
```

Inspect:

```bash
kubectl -n rbac-demo get role pod-viewer -o yaml
```
