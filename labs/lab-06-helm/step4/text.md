# Step 4 — Override values with a file

Create `values.yaml`:

```yaml
replicaCount: 3
image:
  tag: 1.27
service:
  type: ClusterIP
```

Apply it:

```bash
helm upgrade web bitnami/nginx -n web -f values.yaml
kubectl -n web get deploy
helm -n web history web
```
