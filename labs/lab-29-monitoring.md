# Lab 29 — Monitor Cluster and Application Usage

CKA 2026 tests `kubectl top`, cluster event inspection, and understanding how metrics flow from cAdvisor through metrics-server to HPA and kubectl. Optionally, the kube-prometheus-stack gives you the full Prometheus + Grafana observability stack used in production.

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- `kubectl` (pre-installed on Killercoda)
- `metrics-server` (installed in Step 1)
- `helm` (installed via one-line script for optional Prometheus stack)

---

## Step 1 — Install metrics-server

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system patch deploy metrics-server --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
kubectl -n kube-system rollout status deploy/metrics-server --timeout=90s
```

`--kubelet-insecure-tls` is required on Killercoda because the kubelet uses a self-signed certificate.

Wait for the Metrics API to become available:

```bash
until kubectl top node 2>/dev/null; do echo "waiting..."; sleep 5; done
```

---

## Step 2 — kubectl top nodes and Pods

```bash
kubectl top node
kubectl top pod -A
kubectl top pod -A --sort-by=cpu | head -10
kubectl top pod -A --sort-by=memory | head -10
```

`kubectl top` reads from the Metrics API (`metrics.k8s.io/v1beta1`) served by metrics-server.

---

## Step 3 — Generate load to observe metrics

```bash
kubectl run cpu-burner --image=busybox -- sh -c 'while true; do :; done'
kubectl run idle --image=busybox -- sh -c 'sleep 3600'
sleep 30
kubectl top pod --sort-by=cpu
```

`cpu-burner` should appear at the top.

---

## Step 4 — Cluster events (short-term audit trail)

```bash
kubectl get events -A --sort-by=.lastTimestamp | tail -20
kubectl get events --field-selector type=Warning -A
kubectl get events --field-selector involvedObject.name=cpu-burner
```

Events are stored in etcd with a ~1 hour TTL by default — the fastest way to understand recent cluster activity.

---

## Step 5 — cAdvisor raw metrics endpoint

```bash
NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
kubectl get --raw "/api/v1/nodes/$NODE/proxy/stats/summary" | \
  python3 -c "import sys,json; d=json.load(sys.stdin); print(d['node']['cpu'])"
```

cAdvisor runs inside the kubelet and exposes per-container CPU/memory metrics at this endpoint. metrics-server scrapes it every 60 seconds.

---

## Step 6 — Install kube-prometheus-stack (full observability — optional)

```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kp prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set grafana.adminPassword=admin \
  --set prometheus.prometheusSpec.maximumStartupDurationSeconds=120
kubectl -n monitoring rollout status deploy/kp-grafana --timeout=300s
```

Port-forward to access Grafana:

```bash
kubectl -n monitoring port-forward svc/kp-grafana 3000:80 &
```

Open Killercoda's port 3000 traffic panel. Login: `admin` / `admin`.

---

## Step 7 — Sample PromQL queries in Grafana

In Grafana → Explore → Prometheus datasource:

```
# Node CPU usage rate
rate(node_cpu_seconds_total{mode!="idle"}[1m])

# Pod CPU usage
rate(container_cpu_usage_seconds_total{namespace="default"}[1m])

# Pending pods
kube_pod_status_phase{phase="Pending"}
```

---

## Step 8 — Clean up

```bash
kubectl delete pod cpu-burner idle --force --grace-period=0
# Optional Prometheus cleanup:
# helm -n monitoring uninstall kp
# kubectl delete ns monitoring
```

---

## Free online tools

- **metrics-server**: https://github.com/kubernetes-sigs/metrics-server
- **Prometheus docs**: https://prometheus.io/docs/
- **Grafana**: https://grafana.com/docs/
- **kube-prometheus-stack**: https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
- **killer.sh** — CKA mock exam: https://killer.sh
- **Kubernetes docs** (allowed in CKA exam): https://kubernetes.io/docs/

---

## What you learned

- metrics-server feeds `kubectl top` and HPA — it is a prerequisite for both.
- `kubectl top pod --sort-by=cpu` is the exam-day command for resource usage.
- `kubectl get events --sort-by=.lastTimestamp` is faster than `describe` for cluster-wide activity.
- cAdvisor inside kubelet is the raw metrics source; metrics-server aggregates it.
- kube-prometheus-stack is the production-grade observability stack — Prometheus + Grafana + Alertmanager.
