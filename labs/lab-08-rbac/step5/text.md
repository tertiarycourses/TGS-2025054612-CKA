# Step 5 — Test from inside a pod

```bash
kubectl -n rbac-demo run viewer-pod \
  --image=bitnami/kubectl:latest \
  --serviceaccount=viewer \
  --command -- sleep 3600
kubectl -n rbac-demo wait --for=condition=Ready pod/viewer-pod --timeout=60s

kubectl -n rbac-demo exec viewer-pod -- kubectl get pods
kubectl -n rbac-demo exec viewer-pod -- kubectl create deploy nginx --image=nginx
```

The second command must fail with a Forbidden error — proof that RBAC is enforced.
