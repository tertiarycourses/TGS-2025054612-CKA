# Step 6 — Verify the volume lifecycle

```bash
kubectl exec db-0 -- psql -U postgres -c "create table t(x int); insert into t values(1);"
kubectl delete pod db-0
kubectl wait --for=condition=Ready pod/db-0 --timeout=120s
kubectl exec db-0 -- psql -U postgres -c "select * from t;"
```

Data survives the pod restart.
