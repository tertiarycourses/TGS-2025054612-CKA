# Step 1 — Install the Gateway API CRDs

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml
kubectl get crds | grep gateway
```

You'll see `gatewayclasses.gateway.networking.k8s.io`, `gateways...`, `httproutes...`, etc.
