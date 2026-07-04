# Lab 29 — Monitor Cluster and Application Usage

In this lab you install metrics-server, use `kubectl top`, then install the kube-prometheus-stack via Helm for the full Prometheus + Grafana experience.

**Lab environment:** [KillerCoda](https://killercoda.com/tertiary-labs-cka/course/labs/lab-29-monitoring)
---

## Step 1 — Install metrics-server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system patch deploy metrics-server --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
kubectl -n kube-system rollout status deploy/metrics-server --timeout=90s
```

---

## Step 2 — kubectl top

```bash
kubectl top nodes
kubectl top pods -A
kubectl top pods -A --sort-by=cpu | head
kubectl top pods -A --sort-by=memory | head
```

`kubectl top` reads from the Metrics API served by metrics-server.

---

## Step 3 — Events

```bash
kubectl get events --sort-by=.lastTimestamp -A | tail -20
kubectl get events --field-selector type=Warning -A
```

Events are the cluster's audit trail — ~1 hour retention by default.

---

## Step 4 — Container-level stats via cAdvisor (reference)

```bash
NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
kubectl get --raw "/api/v1/nodes/$NODE/proxy/stats/summary" | head -50
```

This raw endpoint feeds metrics-server, Prometheus, and any node-level monitoring agent.

---

## Step 5 — Install kube-prometheus-stack (optional)

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

---

## Step 6 — Sample PromQL queries

In Grafana → Explore → datasource Prometheus:

```
node_cpu_seconds_total
rate(container_cpu_usage_seconds_total{namespace="default"}[1m])
kube_pod_status_phase{phase="Pending"}
```

---

## Step 7 — Cleanup

```bash
# Optional
helm -n monitoring uninstall kp
kubectl delete ns monitoring
```

---

## What you learned
- metrics-server feeds `kubectl top` and HPA.
- Events for short-term audit, Prometheus for long-term metrics.
- The kube-prometheus-stack is the de-facto OSS monitoring deploy.
