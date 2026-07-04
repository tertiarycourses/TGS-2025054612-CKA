# Step 1 — Create a generic Secret

```bash
kubectl create secret generic db-creds \
  --from-literal=username=admin \
  --from-literal=password='S3cure!Pw'
kubectl get secret db-creds -o yaml
```

Notice the base64 values — decode one:

```bash
kubectl get secret db-creds -o jsonpath='{.data.password}' | base64 -d ; echo
```
