# Lab 16 — Pod Scheduling (Limits, Affinity, Taints)

In this lab you control where pods land using resource requests, nodeSelector, node affinity, and taints/tolerations.

**Lab environment:** [Play with Kubernetes](https://killercoda.com/playgrounds/course/kubernetes-playgrounds)
---

## Step 1 — Label your nodes

```bash
kubectl get nodes --show-labels
NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
kubectl label node $NODE disktype=ssd tier=frontend
kubectl get nodes -L disktype,tier
```

---

## Step 2 — nodeSelector

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: ssd-pod }
spec:
  nodeSelector: { disktype: ssd }
  containers:
  - { name: app, image: nginx }
EOF
kubectl get pod ssd-pod -o wide
```

The pod is forced onto the labelled node.

---

## Step 3 — Node affinity (soft preference)

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: affinity-pod }
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - { key: tier, operator: In, values: [frontend] }
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 50
        preference:
          matchExpressions:
          - { key: disktype, operator: In, values: [ssd] }
  containers:
  - { name: app, image: nginx }
EOF
kubectl get pod affinity-pod -o wide
```

`required...` is a hard rule, `preferred...` is a soft hint.

---

## Step 4 — Pod anti-affinity (spread)

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata: { name: spread }
spec:
  replicas: 2
  selector: { matchLabels: { app: spread } }
  template:
    metadata: { labels: { app: spread } }
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels: { app: spread }
            topologyKey: kubernetes.io/hostname
      containers:
      - { name: app, image: nginx }
EOF
kubectl get pods -l app=spread -o wide
```

The two replicas land on different nodes (or one stays Pending if the cluster has only one node).

---

## Step 5 — Resource requests and limits

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: sized }
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests: { cpu: "100m", memory: "64Mi" }
      limits:   { cpu: "500m", memory: "128Mi" }
EOF
kubectl describe pod sized | grep -A3 Limits
```

The scheduler only places the pod on a node with enough **requested** CPU+memory free.

---

## Step 6 — Taints and tolerations

```bash
kubectl taint node $NODE workload=batch:NoSchedule
kubectl run notol --image=nginx
kubectl get pod notol -o wide   # Pending on a single-node cluster
```

Add a toleration:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: tolerant }
spec:
  tolerations:
  - { key: workload, operator: Equal, value: batch, effect: NoSchedule }
  containers:
  - { name: app, image: nginx }
EOF
kubectl get pod tolerant -o wide
```

Remove the taint:

```bash
kubectl taint node $NODE workload-
```

---

## Step 7 — Cleanup

```bash
kubectl delete pod ssd-pod affinity-pod sized tolerant notol --ignore-not-found
kubectl delete deploy spread
kubectl label node $NODE disktype- tier-
```

---

## What you learned
- nodeSelector, node affinity, pod anti-affinity.
- Resource requests drive scheduling; limits cap runtime.
- Taints repel, tolerations let pods bypass them.
