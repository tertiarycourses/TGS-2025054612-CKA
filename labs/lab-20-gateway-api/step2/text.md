# Step 2 — Install a Gateway controller (NGINX Gateway Fabric)

```bash
kubectl apply -f https://raw.githubusercontent.com/nginxinc/nginx-gateway-fabric/v1.4.0/deploy/crds.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/nginx-gateway-fabric/v1.4.0/deploy/manifests/nginx-gateway.yaml
kubectl -n nginx-gateway wait --for=condition=Ready pod -l app.kubernetes.io/name=nginx-gateway-fabric --timeout=180s
kubectl get gatewayclass
```
