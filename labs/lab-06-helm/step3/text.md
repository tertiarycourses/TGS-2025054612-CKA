# Step 3 — Install a chart

```bash
helm install web bitnami/nginx \
  --namespace web --create-namespace \
  --set service.type=ClusterIP \
  --set replicaCount=2
```

`web` is the **release name** — your installation's identity in the cluster.

```bash
kubectl -n web get all
helm -n web list
```
