# Step 1 — Create from literals

```bash
kubectl create configmap app-config \
  --from-literal=APP_ENV=prod \
  --from-literal=APP_TIER=backend
kubectl get configmap app-config -o yaml
```
