# Step 7 — Cleanup

```bash
kubectl delete pod dnsdebug
kubectl delete svc web web-h
kubectl delete deploy web
```

(Revert the Corefile change if you plan to do more labs.)
