# Lab 14 — HPA v2: Install metrics-server, HorizontalPodAutoscaler, Generate Load, Watch Scale-up/down

Horizontal Pod Autoscaling (HPA) automatically adjusts the number of pod replicas based on observed resource utilization. This lab installs the metrics-server to provide CPU and memory metrics, creates an HPA using the `autoscaling/v2` API, generates CPU load using a stress test pod, and watches the HPA scale the Deployment up as load increases and back down as it subsides. HPA is part of the Workloads & Scheduling domain and tests your understanding of resource requests and the metrics pipeline.

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- kubectl v1.35 (pre-installed)
- metrics-server (installed in this lab)

---

## Step 1 — Install metrics-server

```bash
# metrics-server provides CPU and memory metrics to HPA
# It queries kubelet's Summary API on each node

# Install the official metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# For lab environments (self-signed certs), add --kubelet-insecure-tls
# Patch the deployment to disable TLS verification
kubectl patch deployment metrics-server \
  -n kube-system \
  --type=json \
  -p='[{
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--kubelet-insecure-tls"
  }]'

# Wait for metrics-server to be ready
kubectl rollout status deployment metrics-server -n kube-system --timeout=120s

# Test that metrics are available (may take 1-2 minutes to populate)
kubectl top nodes
kubectl top pods -A | head -20
```

metrics-server is a lightweight in-memory collector — it does NOT store historical data. For historical metrics and alerting, use Prometheus + Grafana (Lab 29). The `--kubelet-insecure-tls` flag is only for lab environments; production clusters use proper TLS.

---

## Step 2 — Verify Metrics are Working

```bash
# Wait until kubectl top shows actual values (not errors)
# Retry every 30 seconds until metrics are available
for i in {1..10}; do
  if kubectl top nodes 2>/dev/null | grep -q 'CPU'; then
    echo "Metrics server is ready!"
    kubectl top nodes
    break
  fi
  echo "Waiting for metrics... attempt $i"
  sleep 30
done

# View CPU and memory for all pods
kubectl top pods --all-namespaces --sort-by=cpu | head -20

# View metrics for specific pods
kubectl top pods -n kube-system
```

`kubectl top` is the primary tool for viewing live resource usage. If it returns an error, metrics-server is not ready or not installed. The HPA controller queries the same metrics API.

---

## Step 3 — Create a CPU-Intensive Deployment

```bash
# Create a deployment with CPU requests (REQUIRED for CPU-based HPA)
# HPA calculates utilization as: actual CPU / request CPU
# Without requests, HPA cannot calculate a meaningful percentage

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
spec:
  selector:
    matchLabels:
      run: php-apache
  replicas: 1
  template:
    metadata:
      labels:
        run: php-apache
    spec:
      containers:
      - name: php-apache
        image: registry.k8s.io/hpa-example
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 200m      # REQUIRED: HPA calculates % based on this
            memory: 64Mi
          limits:
            cpu: 500m
            memory: 128Mi
---
apiVersion: v1
kind: Service
metadata:
  name: php-apache
spec:
  ports:
  - port: 80
  selector:
    run: php-apache
EOF

kubectl rollout status deployment php-apache --timeout=60s
kubectl get pods -l run=php-apache
```

The `registry.k8s.io/hpa-example` image runs a PHP server that performs mathematical calculations when hit with HTTP requests, making it perfect for CPU load testing. Resource requests are MANDATORY for percentage-based HPA.

---

## Step 4 — Create HPA Using autoscaling/v2

```bash
# Create HPA using the v2 API (recommended for CKA 2026)
cat <<'EOF' | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50    # Target: 50% of CPU request
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80    # Target: 80% of memory request
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0    # Scale up immediately
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15    # Can double replicas every 15 seconds
    scaleDown:
      stabilizationWindowSeconds: 300  # Wait 5 minutes before scaling down
      policies:
      - type: Pods
        value: 1
        periodSeconds: 60    # Remove at most 1 pod per minute
EOF

# View the HPA
kubectl get hpa php-apache-hpa
# NAME             REFERENCE              TARGETS   MINPODS   MAXPODS   REPLICAS
# php-apache-hpa   Deployment/php-apache  0%/50%    1         10        1
```

`autoscaling/v2` supports multiple metric sources and fine-grained scaling behavior. The `stabilizationWindowSeconds` for scale-down prevents thrashing — the HPA waits 5 minutes after load drops before removing pods.

---

## Step 5 — Inspect the HPA Status

```bash
# Detailed HPA status
kubectl describe hpa php-apache-hpa

# Output shows:
# Metrics: cpu resource utilization (percentage of request): 0% / 50%
#          memory resource utilization (percentage of request): 10% / 80%
# Min replicas: 1
# Max replicas: 10
# Deployment pods: 1 current / 1 desired

# Wait for metrics to populate
kubectl get hpa php-apache-hpa -w
# Watch the TARGETS column populate

# The HPA uses these conditions:
# ScalingActive: True = HPA is actively scaling
# AbleToScale:   True = HPA can scale the target
# ScalingLimited: True = at min/max boundary
```

The HPA enters a `ScalingLimited` condition when the replica count has reached `minReplicas` or `maxReplicas`. Check `kubectl describe hpa` for detailed conditions and events during troubleshooting.

---

## Step 6 — Generate CPU Load

```bash
# Run a load generator to stress the php-apache service
kubectl run load-generator \
  --image=busybox:1.28 \
  --restart=Never \
  -- /bin/sh -c "while true; do wget -q -O- http://php-apache; done"

# Monitor the load generator is running
kubectl get pod load-generator

echo "Load generator started. Watching HPA scale..."
echo "This will take 1-3 minutes to trigger scale-up"
```

The load generator sends continuous HTTP requests to the service, increasing CPU utilization above the 50% target. The HPA controller polls metrics every 15 seconds (default sync period) and begins scaling when the target is exceeded.

---

## Step 7 — Watch Scale-Up

```bash
# Watch the HPA in real time
kubectl get hpa php-apache-hpa -w
# TARGETS will increase: 0%/50% → 85%/50% → 250%/50%
# REPLICAS will increase: 1 → 4 → 7

# In another window, watch pods being created
kubectl get pods -l run=php-apache -w
# New pods appear with STATUS: Pending → ContainerCreating → Running

# Also watch the Deployment
kubectl rollout status deployment php-apache

# Check actual CPU values
kubectl top pods -l run=php-apache

# HPA calculation:
# If current CPU = 250% of request, target = 50%:
# desiredReplicas = ceil(currentReplicas * (currentUtil/targetUtil))
# desiredReplicas = ceil(1 * (250/50)) = ceil(5) = 5
```

Scale-up happens relatively quickly (within 1-3 minutes). The HPA uses the average CPU utilization across all pods and calculates the number of replicas needed to bring it back to the target.

---

## Step 8 — Stop the Load and Watch Scale-Down

```bash
# Stop the load generator
kubectl delete pod load-generator

echo "Load stopped. Watching scale-down..."
echo "Scale-down uses a 5-minute stabilization window"

# Watch HPA — scale-down will be delayed by stabilizationWindowSeconds=300
kubectl get hpa php-apache-hpa -w

# The TARGETS will drop: 250%/50% → 50%/50% → 5%/50%
# But replicas won't decrease for ~5 minutes after CPU drops

# After 5 minutes, pods will be removed one at a time (1 per 60 seconds)
kubectl get pods -l run=php-apache -w
```

Scale-down is intentionally slow to prevent flapping (rapid scale-up/down cycles). The `stabilizationWindowSeconds: 300` means the HPA must see below-target utilization for 5 continuous minutes before removing pods.

---

## Step 9 — Create HPA with kubectl autoscale (Imperative)

```bash
# Quick HPA creation using imperative command (useful in exam)
kubectl autoscale deployment php-apache \
  --min=1 \
  --max=10 \
  --cpu-percent=50

# This creates an autoscaling/v2 HPA (in Kubernetes v1.25+)
kubectl get hpa

# For exam: generate the YAML without creating
kubectl autoscale deployment php-apache \
  --min=1 --max=10 --cpu-percent=50 \
  --dry-run=client -o yaml
```

`kubectl autoscale` is the fastest way to create an HPA in an exam. It only supports CPU utilization — for memory or custom metrics, you need the declarative YAML approach.

---

## Step 10 — Advanced HPA: Custom Behavior Policies

```bash
# Production-grade HPA with aggressive scale-up and conservative scale-down
cat <<'EOF' | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: production-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 2    # Always keep at least 2 replicas for HA
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0
      selectPolicy: Max
      policies:
      - type: Pods
        value: 4
        periodSeconds: 60    # Add up to 4 pods per minute
      - type: Percent
        value: 100
        periodSeconds: 60    # Or double every minute (whichever is larger)
    scaleDown:
      stabilizationWindowSeconds: 600   # 10 minutes before scale-down
      selectPolicy: Min
      policies:
      - type: Pods
        value: 2
        periodSeconds: 120   # Remove at most 2 pods per 2 minutes
EOF

kubectl describe hpa production-hpa
```

`selectPolicy: Max` for scale-up chooses the policy that results in the most pods (aggressive). `selectPolicy: Min` for scale-down chooses the policy that removes the fewest pods (conservative).

---

## Step 11 — Clean Up

```bash
kubectl delete hpa php-apache-hpa production-hpa
kubectl delete deployment php-apache
kubectl delete svc php-apache
kubectl delete pod load-generator 2>/dev/null || true
```

---

## Free online tools
- **Kubernetes Docs — HPA**: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
- **Kubernetes Docs — HPA Walkthrough**: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/
- **killer.sh** — CKA mock exam: https://killer.sh

---

## What you learned
- metrics-server provides real-time CPU and memory metrics to HPA; install with `--kubelet-insecure-tls` in lab environments
- `kubectl top nodes` and `kubectl top pods` show live resource usage from metrics-server
- CPU requests on pods are REQUIRED for CPU-based HPA; without them, HPA cannot calculate utilization %
- `autoscaling/v2` HPA supports multiple metrics (CPU + memory + custom) and behavior policies
- `averageUtilization: 50` means HPA targets 50% of the CPU request across all pods
- Scale-up is fast; scale-down uses `stabilizationWindowSeconds` (default 300s) to prevent thrashing
- `behavior.scaleDown.selectPolicy: Min` is conservative; `scaleUp.selectPolicy: Max` is aggressive
- `kubectl autoscale` is the imperative command for quickly creating CPU-based HPAs
- HPA formula: `desiredReplicas = ceil(currentReplicas * currentUtilization / targetUtilization)`
- Always set `minReplicas: 2` for production workloads to maintain HA during scale-down events
