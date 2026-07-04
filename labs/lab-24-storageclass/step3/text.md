# Step 3 — Mark it as default

```bash
kubectl patch storageclass local-path \
  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl get sc
```

The `(default)` marker appears next to `local-path`.
