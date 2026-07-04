# Lab 15 — Self-Healing Primitives

Kubernetes self-healing relies on four pillars: liveness/readiness/startup probes, ReplicaSets, DaemonSets, and StatefulSets. In this lab you exercise each one.

**Lab environment:** [Play with Kubernetes](https://killercoda.com/playgrounds/course/kubernetes-playgrounds/two-node)
---

## Step 1 — Liveness probe

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: live-demo }
spec:
  containers:
  - name: app
    image: busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm /tmp/healthy; sleep 600
    livenessProbe:
      exec: { command: ["cat","/tmp/healthy"] }
      initialDelaySeconds: 5
      periodSeconds: 5
EOF
kubectl get pod live-demo -w
```

After ~35 s the probe fails, kubelet restarts the container, `RESTARTS` counter increments.

---

## Step 2 — Readiness probe

```bash
kubectl run ready-demo --image=nginx \
  --overrides='{"spec":{"containers":[{"name":"ready-demo","image":"nginx","readinessProbe":{"httpGet":{"path":"/","port":80},"initialDelaySeconds":3,"periodSeconds":3}}]}}'
kubectl get pod ready-demo -w
```

`READY 0/1` until the probe passes, then `1/1`. Readiness gates Service endpoints — failing pods are removed from the load balancer but **not** restarted.

---

## Step 3 — ReplicaSet self-heal

```bash
kubectl create deployment rs-demo --image=nginx --replicas=3
kubectl get pods -l app=rs-demo
POD=$(kubectl get pods -l app=rs-demo -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD
kubectl get pods -l app=rs-demo -w
```

A new pod is spawned within seconds. The ReplicaSet controller continuously reconciles `desired` vs `actual`.

---

## Step 4 — DaemonSet (one pod per node)

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata: { name: log-agent, namespace: kube-system }
spec:
  selector: { matchLabels: { app: log-agent } }
  template:
    metadata: { labels: { app: log-agent } }
    spec:
      tolerations:
      - operator: Exists
      containers:
      - name: agent
        image: busybox
        command: ["sh","-c","while true; do echo log; sleep 60; done"]
EOF
kubectl -n kube-system get ds log-agent
kubectl -n kube-system get pods -l app=log-agent -o wide
```

You should see one pod per node (including the control plane, thanks to the `Exists` toleration).

---

## Step 5 — StatefulSet (stable identity + storage)

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata: { name: web-headless }
spec:
  clusterIP: None
  selector: { app: web-ss }
  ports: [{ port: 80 }]
---
apiVersion: apps/v1
kind: StatefulSet
metadata: { name: web-ss }
spec:
  serviceName: web-headless
  replicas: 3
  selector: { matchLabels: { app: web-ss } }
  template:
    metadata: { labels: { app: web-ss } }
    spec:
      containers:
      - name: nginx
        image: nginx
        ports: [{ containerPort: 80 }]
EOF
kubectl rollout status statefulset/web-ss
kubectl get pods -l app=web-ss
```

Pods are named `web-ss-0`, `web-ss-1`, `web-ss-2` — stable identities. The headless Service gives each pod a DNS A record: `web-ss-0.web-headless.default.svc.cluster.local`.

---

## Step 6 — Cleanup

```bash
kubectl delete pod live-demo ready-demo
kubectl delete deploy rs-demo
kubectl -n kube-system delete ds log-agent
kubectl delete statefulset web-ss
kubectl delete svc web-headless
```

---

## What you learned
- Liveness restarts, readiness gates traffic, startup protects slow-boot apps.
- ReplicaSet, DaemonSet, StatefulSet — three different "shape" controllers.
- Headless Service + StatefulSet gives stable network identity.
