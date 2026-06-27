# Lab 15 — Self-Healing: Liveness/Readiness Probes, ReplicaSet Self-Heal, DaemonSet, StatefulSet Stable Identity

Kubernetes self-healing is one of its most powerful features — it automatically restarts failed containers, reschedules pods on healthy nodes, and maintains the desired number of replicas. This lab configures liveness and readiness probes to control container health, demonstrates ReplicaSet self-healing when pods are manually deleted, deploys a DaemonSet that runs one pod per node, and creates a StatefulSet with stable network identity and ordered deployment. These concepts appear throughout the CKA exam.

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- kubectl v1.35 (pre-installed)

---

## Step 1 — Liveness Probe: Restart Unhealthy Containers

```bash
# Liveness probe: if it fails, kubelet restarts the container
# Types: httpGet, tcpSocket, exec, grpc

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: liveness-http
spec:
  containers:
  - name: webapp
    image: nginx:alpine
    ports:
    - containerPort: 80
    livenessProbe:
      httpGet:
        path: /healthz
        port: 80
      initialDelaySeconds: 10    # Wait 10s after container starts
      periodSeconds: 5           # Check every 5 seconds
      timeoutSeconds: 2          # Fail if no response within 2s
      failureThreshold: 3        # Restart after 3 consecutive failures
      successThreshold: 1        # 1 success to be considered live
---
apiVersion: v1
kind: Pod
metadata:
  name: liveness-exec
spec:
  containers:
  - name: app
    image: busybox
    command:
    - /bin/sh
    - -c
    - "touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 600"
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy        # Returns 0 if file exists, nonzero if not
      initialDelaySeconds: 5
      periodSeconds: 5
      failureThreshold: 3
EOF

kubectl get pods -w
# After ~45 seconds, liveness-exec will start restarting
# (healthy file deleted at 30s, 3 failures at 5s intervals = 15s = total 45s)
```

`liveness` probes restart the container — they do not affect whether the pod receives traffic. Use liveness probes to detect deadlocks or infinite loops where the container is running but not functioning.

---

## Step 2 — Watch Liveness Probe Trigger a Restart

```bash
# Watch the liveness-exec pod
kubectl describe pod liveness-exec | grep -A 10 'Liveness'
# Liveness: exec [cat /tmp/healthy] delay=5s timeout=1s period=5s #success=1 #failure=3

# After the file is removed (30 seconds):
kubectl describe pod liveness-exec | grep -A 20 'Events:'
# Warning Unhealthy: Liveness probe failed: cat: /tmp/healthy: No such file or directory
# Normal  Killing:   Container app failed liveness probe, will be restarted

# Check restart count
kubectl get pod liveness-exec
# NAME            READY   STATUS    RESTARTS   AGE
# liveness-exec   1/1     Running   1          2m

# RESTARTS counter increases with each container restart
kubectl get pod liveness-exec -o jsonpath='{.status.containerStatuses[0].restartCount}'
```

High restart counts (visible in `kubectl get pods`) are a key diagnostic signal — they indicate liveness probe failures. `kubectl describe pod` shows the probe configuration and failure events.

---

## Step 3 — Readiness Probe: Control Traffic Admission

```bash
# Readiness probe: if it fails, pod is removed from service endpoints
# Container stays running but receives no traffic

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5   # Wait 5s before first check
          periodSeconds: 10
          failureThreshold: 3
          successThreshold: 1
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 15  # Give more time before liveness kicks in
          periodSeconds: 20
          failureThreshold: 3
---
apiVersion: v1
kind: Service
metadata:
  name: webapp
spec:
  selector:
    app: webapp
  ports:
  - port: 80
EOF

kubectl rollout status deployment webapp
kubectl get endpoints webapp
# Endpoints shows only READY pods
```

`readiness` probes gate traffic admission. During a rolling update, new pods only receive traffic after their readiness probe passes. This prevents traffic from going to pods that haven't finished starting up.

---

## Step 4 — Simulate Readiness Probe Failure

```bash
# Get the name of one pod
POD_NAME=$(kubectl get pods -l app=webapp -o name | head -1 | cut -d/ -f2)

# Simulate readiness failure by removing nginx config (causes 404)
kubectl exec $POD_NAME -- mv /etc/nginx/conf.d/default.conf /tmp/

# Wait for the readiness probe to fail (10s period, 3 failures = 30s)
sleep 35

# Check endpoints — the failing pod's IP should be removed
kubectl get endpoints webapp
# Address list decreases from 3 IPs to 2 IPs

kubectl get pods
# NAME         READY   STATUS    RESTARTS
# webapp-xxx   0/1     Running   0        <- not ready (0/1)
# webapp-xxx   1/1     Running   0
# webapp-xxx   1/1     Running   0

# Restore the nginx config
kubectl exec $POD_NAME -- mv /tmp/default.conf /etc/nginx/conf.d/
sleep 15
kubectl get endpoints webapp
# Pod is re-added to endpoints after readiness probe passes
```

The pod stays `Running` but shows `0/1` in the READY column. It's excluded from service endpoints, so no traffic reaches it. No restart occurs — that's the key difference from liveness probes.

---

## Step 5 — ReplicaSet Self-Healing

```bash
# Create a ReplicaSet directly (usually Deployments manage RS, but good to understand)
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: self-heal-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: self-heal
  template:
    metadata:
      labels:
        app: self-heal
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
EOF

kubectl get pods -l app=self-heal
# 3 pods running

# Delete one pod manually
POD1=$(kubectl get pods -l app=self-heal -o name | head -1)
kubectl delete $POD1

# Watch the ReplicaSet immediately create a replacement
kubectl get pods -l app=self-heal -w
# New pod appears within seconds

# Delete all pods at once
kubectl delete pods -l app=self-heal

# ReplicaSet creates 3 new pods to maintain desired state
kubectl get pods -l app=self-heal
# 3 new pods appear

kubectl describe rs self-heal-rs | grep -A 5 'Events:'
# Normal SuccessfulCreate  pod/self-heal-rs-xxxxx created
```

The ReplicaSet controller continuously compares desired vs actual pod count. When a pod is deleted (or dies), the controller creates a replacement immediately. This is the core self-healing mechanism.

---

## Step 6 — DaemonSet: One Pod Per Node

```bash
# DaemonSet runs exactly one pod on every node
# Use cases: log collectors, monitoring agents, CNI plugins, kube-proxy

cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-monitor
spec:
  selector:
    matchLabels:
      app: node-monitor
  template:
    metadata:
      labels:
        app: node-monitor
    spec:
      tolerations:
      - operator: Exists    # Run on ALL nodes including control plane
        effect: NoSchedule  # Tolerate the control-plane:NoSchedule taint
      containers:
      - name: monitor
        image: busybox
        command: ["sh", "-c", "while true; do echo \"Node: $NODE_NAME\"; sleep 60; done"]
        env:
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        resources:
          requests:
            cpu: 10m
            memory: 16Mi
EOF

kubectl get daemonset node-monitor
# DESIRED == CURRENT == READY == number of nodes

kubectl get pods -l app=node-monitor -o wide
# One pod per node, each showing different NODE
```

DaemonSets automatically add pods to new nodes when they join the cluster and remove pods when nodes are removed. Without the `tolerations` for `NoSchedule`, the DaemonSet won't run on the control plane node.

---

## Step 7 — StatefulSet: Stable Identity and Ordered Deployment

```bash
# StatefulSet provides:
# 1. Stable, unique pod names: <name>-0, <name>-1, <name>-2
# 2. Stable network identity via headless service
# 3. Ordered, graceful deployment and scaling
# 4. Persistent storage per pod (volumeClaimTemplates)

# Create a headless service (required for stable DNS)
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: nginx-headless
  labels:
    app: nginx-sts
spec:
  ports:
  - port: 80
  clusterIP: None    # Headless: no cluster IP, DNS resolves to pod IPs
  selector:
    app: nginx-sts
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: nginx-sts
spec:
  serviceName: nginx-headless    # Must match the headless service name
  replicas: 3
  selector:
    matchLabels:
      app: nginx-sts
  template:
    metadata:
      labels:
        app: nginx-sts
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: data
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: "standard"
      resources:
        requests:
          storage: 1Gi
EOF

kubectl get statefulset nginx-sts
kubectl get pods -l app=nginx-sts
# Pods: nginx-sts-0, nginx-sts-1, nginx-sts-2 (ordered)
```

StatefulSets deploy pods in order: 0, 1, 2 — and each must be `Running` and `Ready` before the next starts. Deletion is reverse order: 2, 1, 0. This ordering enables database leader/follower initialization patterns.

---

## Step 8 — Verify StatefulSet Stable DNS

```bash
# Wait for all pods to be ready
kubectl rollout status statefulset nginx-sts --timeout=120s

# StatefulSet pods get DNS in the format:
# <pod-name>.<service-name>.<namespace>.svc.cluster.local

# Test DNS resolution
kubectl run dns-test --image=busybox:1.28 --restart=Never \
  -- nslookup nginx-sts-0.nginx-headless.default.svc.cluster.local

kubectl logs dns-test
# Address: <pod IP of nginx-sts-0>

# Each pod gets a unique, predictable DNS name
for i in 0 1 2; do
  kubectl run dns-$i --image=busybox:1.28 --restart=Never \
    -- nslookup nginx-sts-$i.nginx-headless.default.svc.cluster.local
done

for i in 0 1 2; do
  echo "=== nginx-sts-$i ==="
  kubectl logs dns-$i 2>/dev/null
done

# Clean up test pods
kubectl delete pods dns-test dns-0 dns-1 dns-2 2>/dev/null
```

Stable DNS is why StatefulSets are used for databases: `mysql-0.mysql-headless.default.svc.cluster.local` always resolves to the same pod, even after restarts. This allows replicas to find the primary by name.

---

## Step 9 — StatefulSet Self-Healing with Stable Identity

```bash
# Delete nginx-sts-1 pod
kubectl delete pod nginx-sts-1

# Watch it restart with the SAME name
kubectl get pods -l app=nginx-sts -w
# nginx-sts-1 is replaced with a new pod named nginx-sts-1
# (same name, same PVC, same DNS name)

# Check that the PVC is reused (not replaced)
kubectl get pvc
# data-nginx-sts-0, data-nginx-sts-1, data-nginx-sts-2
# After pod restart, nginx-sts-1 reattaches to data-nginx-sts-1

# StatefulSet identity is preserved across restarts:
# Same pod name: nginx-sts-1
# Same DNS:      nginx-sts-1.nginx-headless.default.svc.cluster.local
# Same PVC:      data-nginx-sts-1
```

When a StatefulSet pod restarts, it gets the same ordinal index, the same DNS name, and reattaches to the same PVC. This "sticky identity" makes stateful applications like databases viable in Kubernetes.

---

## Step 10 — Clean Up

```bash
kubectl delete daemonset node-monitor
kubectl delete statefulset nginx-sts
kubectl delete svc nginx-headless webapp
kubectl delete deployment webapp
kubectl delete replicaset self-heal-rs
kubectl delete pod liveness-http liveness-exec 2>/dev/null
kubectl delete pvc -l app=nginx-sts
```

---

## Free online tools
- **Kubernetes Docs — Probes**: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- **Kubernetes Docs — StatefulSets**: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
- **Kubernetes Docs — DaemonSets**: https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/
- **killer.sh** — CKA mock exam: https://killer.sh

---

## What you learned
- Liveness probes restart the container when they fail; readiness probes remove pods from service endpoints
- `initialDelaySeconds` prevents probe failures during container startup initialization
- `failureThreshold: 3` gives the container three chances before action is taken
- ReplicaSets continuously reconcile desired vs actual pod count — deleted pods are immediately replaced
- DaemonSets ensure exactly one pod per node; use tolerations to run on control plane nodes
- StatefulSets provide stable pod names (`<name>-0`, `<name>-1`) and stable DNS via headless services
- StatefulSet pods deploy in order (0, 1, 2) and delete in reverse (2, 1, 0)
- Deleted StatefulSet pods restart with the same name, DNS, and PVC — sticky identity
- Headless services (`clusterIP: None`) provide per-pod DNS without a load-balancing VIP
- High `RESTARTS` count in `kubectl get pods` indicates liveness probe failures
