# Step 4 — Test with `kubectl auth can-i`

```bash
kubectl -n rbac-demo auth can-i list pods       --as=system:serviceaccount:rbac-demo:viewer
kubectl -n rbac-demo auth can-i create pods     --as=system:serviceaccount:rbac-demo:viewer
kubectl -n rbac-demo auth can-i list deployments --as=system:serviceaccount:rbac-demo:viewer
```

You should see `yes`, `no`, `no`.
