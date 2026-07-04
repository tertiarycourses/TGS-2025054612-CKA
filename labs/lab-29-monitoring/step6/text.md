# Step 6 — Sample PromQL queries

In Grafana → Explore → datasource Prometheus:

```
node_cpu_seconds_total
rate(container_cpu_usage_seconds_total{namespace="default"}[1m])
kube_pod_status_phase{phase="Pending"}
```
