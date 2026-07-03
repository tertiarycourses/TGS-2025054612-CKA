# Step 3 — Install a real operator (cert-manager)

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set crds.enabled=true
kubectl -n cert-manager get pods
```

This installs the cert-manager Deployments **and** several CRDs:

```bash
kubectl get crds | grep cert-manager
```

You should see `certificates`, `issuers`, `clusterissuers`, `certificaterequests`, `orders`, `challenges`.
