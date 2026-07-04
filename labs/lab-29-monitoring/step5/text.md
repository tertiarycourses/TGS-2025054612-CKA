# Step 5 — Install kube-prometheus-stack (optional)

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kp prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set grafana.adminPassword=admin \
  --set prometheus.prometheusSpec.maximumStartupDurationSeconds=120
kubectl -n monitoring rollout status deploy/kp-grafana --timeout=180s
kubectl -n monitoring get pods
```

Expose Grafana with a port-forward:

```bash
kubectl -n monitoring port-forward svc/kp-grafana 3000:80 &
```

Then click the **30s preview link** in Killercoda's traffic panel for port 3000. Login `admin / admin`.
