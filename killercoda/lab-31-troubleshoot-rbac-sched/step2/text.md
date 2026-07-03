# Step 2 — Diagnose with `auth can-i`

```bash
kubectl -n app auth can-i list pods --as=system:serviceaccount:app:worker
kubectl -n app auth can-i list pods --as=system:serviceaccount:app:worker -v=6 2>&1 | grep -i forbidden
```
