# Step 6 — Pending due to taint

```bash
NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
kubectl taint node $NODE dedicated=critical:NoSchedule
kubectl -n app run untol --image=nginx
kubectl -n app describe pod untol | tail -10
```

`untolerated taint {dedicated: critical}`.

Fix:

```bash
kubectl taint node $NODE dedicated-
```
