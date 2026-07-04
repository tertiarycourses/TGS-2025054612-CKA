# Step 7 — Cleanup

```bash
kubectl delete statefulset db
kubectl delete svc db-headless
kubectl delete pvc -l app=db
kubectl delete pvc data-pvc
```

PVCs created by `volumeClaimTemplates` are **not** auto-deleted; clean them up explicitly.
