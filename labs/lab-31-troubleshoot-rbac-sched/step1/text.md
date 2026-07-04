# Step 1 — Create a broken setup

```bash
kubectl create ns app
kubectl -n app create sa worker
kubectl -n app run worker-pod --image=bitnami/kubectl --serviceaccount=worker \
  --command -- sleep 3600
kubectl -n app wait --for=condition=Ready pod/worker-pod --timeout=60s

kubectl -n app exec worker-pod -- kubectl get pods
# Forbidden
```
