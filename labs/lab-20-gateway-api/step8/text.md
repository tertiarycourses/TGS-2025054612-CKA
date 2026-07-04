# Step 8 — Cleanup

```bash
kubectl delete httproute echo-route
kubectl delete gateway web
kubectl delete svc echo && kubectl delete deploy echo
```
