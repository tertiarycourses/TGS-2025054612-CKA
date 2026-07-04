# Step 2 — Add a chart repository

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm search repo bitnami/nginx
```

`helm repo update` refreshes the local index. `helm search` queries it.
