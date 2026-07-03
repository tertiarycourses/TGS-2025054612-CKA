# Step 6 — Reclaim behavior

```bash
kubectl delete pod web
kubectl delete pvc pvc-host
kubectl get pv pv-host
```

The PV stays in `Released` (Retain policy). To re-use it, edit and clear `spec.claimRef`, or change reclaim policy to `Delete`.
