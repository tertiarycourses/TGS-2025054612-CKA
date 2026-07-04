# Step 4 — Render and apply

```bash
kubectl create ns web-dev
kubectl create ns web-prod
kubectl kustomize kustom/overlays/dev | head -30
kubectl apply -k kustom/overlays/dev
kubectl apply -k kustom/overlays/prod
kubectl -n web-dev get deploy
kubectl -n web-prod get deploy
```

Notice both deployments come from the same base, but with different replicas and image tags.
