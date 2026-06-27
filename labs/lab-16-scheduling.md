# Lab 16 — Scheduling: nodeSelector, Node Affinity Required/Preferred, Taints + Tolerations, Resource Requests/Limits

The Kubernetes scheduler places pods on nodes based on resource availability, node labels, taints/tolerations, and affinity rules. This lab explores each scheduling mechanism: nodeSelector for simple label matching, node affinity for flexible required and preferred placement, taints to repel pods from nodes, tolerations to allow specific pods through taints, and resource requests/limits for capacity-based scheduling. These concepts represent the core of the Workloads & Scheduling domain.

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- kubectl v1.35 (pre-installed)

---

## Step 1 — Label Nodes for Scheduling

```bash
# View existing node labels
kubectl get nodes --show-labels
kubectl describe node <node-name> | grep -A 20 'Labels:'

# Add custom labels to nodes
# (In a 2-node cluster: controlplane and worker01)
kubectl label node worker01 disk=ssd
kubectl label node worker01 region=us-east
kubectl label node worker01 environment=production

# Label the control plane node
kubectl label node controlplane disk=hdd
kubectl label node controlplane region=us-east
kubectl label node controlplane environment=development

# Verify labels
kubectl get nodes -L disk,region,environment
# NAME           STATUS   ROLES           DISK   REGION     ENVIRONMENT
# controlplane   Ready    control-plane   hdd    us-east    development
# worker01       Ready    <none>          ssd    us-east    production
```

Node labels are arbitrary key-value pairs. Built-in labels (starting with `kubernetes.io/` or `node.kubernetes.io/`) are set automatically by kubelet. Custom labels enable workload placement targeting.

---

## Step 2 — nodeSelector: Simple Label Matching

```bash
# nodeSelector requires an EXACT label match
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ssd-pod
spec:
  nodeSelector:
    disk: ssd              # Only schedule on nodes with disk=ssd
  containers:
  - name: app
    image: nginx:alpine
EOF

# Verify it landed on worker01 (which has disk=ssd)
kubectl get pod ssd-pod -o wide
# NODE column should show worker01

# Create a pod that won't schedule (no node has disk=nvme)
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: nvme-pod
spec:
  nodeSelector:
    disk: nvme             # No node has this label
  containers:
  - name: app
    image: nginx:alpine
EOF

kubectl get pod nvme-pod
# STATUS: Pending — no matching node

kubectl describe pod nvme-pod | grep -A 5 'Events:'
# Warning  FailedScheduling  0/2 nodes are available: 2 node(s) didn't match Pod's node affinity/selector
```

`nodeSelector` is the simplest scheduling constraint. It supports only exact equality matching. For more flexible rules (OR conditions, preference-based placement), use node affinity.

---

## Step 3 — Node Affinity: Required Rules (Hard Constraint)

```bash
# requiredDuringSchedulingIgnoredDuringExecution = Hard constraint
# Pod MUST be placed on matching nodes; stays if node labels change after scheduling

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: affinity-required
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disk
            operator: In
            values:
            - ssd
            - nvme        # OR: disk is ssd OR nvme
          - key: environment
            operator: In
            values:
            - production  # AND: environment is production
        # Multiple nodeSelectorTerms = OR between terms
        # Multiple matchExpressions within a term = AND
  containers:
  - name: app
    image: nginx:alpine
EOF

kubectl get pod affinity-required -o wide
# Lands on worker01 (disk=ssd AND environment=production)

# Supported operators:
# In, NotIn, Exists, DoesNotExist, Gt, Lt
```

Node affinity supports operators `In`, `NotIn`, `Exists`, `DoesNotExist`, `Gt`, `Lt`. Multiple `matchExpressions` in one `nodeSelectorTerms` item are ANDed together. Multiple `nodeSelectorTerms` items are ORed.

---

## Step 4 — Node Affinity: Preferred Rules (Soft Constraint)

```bash
# preferredDuringSchedulingIgnoredDuringExecution = Soft constraint
# Scheduler tries to match, but places the pod even if no match exists

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: affinity-preferred
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 80          # Higher weight = more strongly preferred
        preference:
          matchExpressions:
          - key: disk
            operator: In
            values:
            - ssd
      - weight: 20          # Weaker preference
        preference:
          matchExpressions:
          - key: region
            operator: In
            values:
            - us-west
  containers:
  - name: app
    image: nginx:alpine
EOF

# Pod schedules even if no preferred node exists (falls back to any available node)
kubectl get pod affinity-preferred -o wide

# Combine required AND preferred:
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: affinity-combined
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: region
            operator: In
            values:
            - us-east        # MUST be in us-east
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        preference:
          matchExpressions:
          - key: disk
            operator: In
            values:
            - ssd            # PREFER ssd (but will accept hdd in us-east)
  containers:
  - name: app
    image: nginx:alpine
EOF
```

The `weight` field (1-100) determines how strongly the scheduler prefers a matching node. The scheduler sums weights from all matching preferences and picks the node with the highest score.

---

## Step 5 — Taints: Repel Pods from Nodes

```bash
# Taints mark a node as "not suitable" for pods without matching tolerations

# Add a taint to the worker node
kubectl taint node worker01 gpu=true:NoSchedule
# Effect options:
# NoSchedule:        New pods without toleration are not scheduled
# PreferNoSchedule:  Scheduler tries to avoid, but not guaranteed
# NoExecute:         Existing pods without toleration are evicted too

# View taints on a node
kubectl describe node worker01 | grep Taints
# Taints: gpu=true:NoSchedule

# Create a pod WITHOUT toleration (will not schedule on worker01)
kubectl run no-toleration-pod --image=nginx:alpine

kubectl get pod no-toleration-pod -o wide
# In a 2-node cluster, it will land on controlplane (if schedulable)

# Add another taint to controlplane (makes it completely restricted)
kubectl taint node controlplane dedicated=control-plane:NoSchedule
# This might already exist from kubeadm: node-role.kubernetes.io/control-plane:NoSchedule
```

Taints work opposite to node affinity: instead of attracting pods to nodes, they repel pods FROM nodes. Only pods with matching tolerations can be placed on tainted nodes.

---

## Step 6 — Tolerations: Allow Pods on Tainted Nodes

```bash
# Create a pod with a toleration for the gpu taint
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: gpu-pod
spec:
  tolerations:
  - key: gpu
    operator: Equal
    value: "true"
    effect: NoSchedule    # Must match the taint exactly
  nodeSelector:
    disk: ssd             # Also pin to the GPU node
  containers:
  - name: app
    image: nvidia/cuda:12.0-base-ubuntu20.04
    command: ["sleep", "infinity"]
EOF

# The pod can now schedule on worker01 despite the gpu taint
kubectl get pod gpu-pod -o wide
# NODE: worker01

# Tolerate ALL taints on a node (broad toleration)
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: tolerant-pod
spec:
  tolerations:
  - operator: Exists      # Tolerate ANY taint key with ANY value
  containers:
  - name: app
    image: nginx:alpine
EOF
# This pod can schedule on any node including control plane

# View the built-in tolerations added by system pods
kubectl get pod -n kube-system coredns-xxxxxx -o yaml | grep -A 20 tolerations
```

The `operator: Exists` toleration without a key tolerates all taints. DaemonSets use this pattern with specific effects to run on all nodes including tainted ones.

---

## Step 7 — NoExecute Taint: Evict Running Pods

```bash
# NoExecute evicts running pods without matching tolerations

# First, run some pods on worker01
kubectl run workload-1 --image=nginx:alpine
kubectl run workload-2 --image=nginx:alpine
kubectl get pods -o wide | grep worker01

# Add a NoExecute taint (simulates node going into maintenance)
kubectl taint node worker01 maintenance=true:NoExecute

# Watch pods get evicted from worker01
kubectl get pods -w
# Pods without toleration are terminated and rescheduled elsewhere

# Add a toleration with tolerationSeconds (stay for 5 minutes then evict)
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: graceful-pod
spec:
  tolerations:
  - key: maintenance
    operator: Equal
    value: "true"
    effect: NoExecute
    tolerationSeconds: 300    # Stay for 5 minutes, then evict
  containers:
  - name: app
    image: nginx:alpine
EOF

# Remove the taint when maintenance is done
kubectl taint node worker01 maintenance=true:NoExecute-
# The - at the end removes the taint
```

`tolerationSeconds` on a `NoExecute` toleration gives pods a grace period on a tainted node before eviction. This allows gradual draining of workloads rather than immediate eviction.

---

## Step 8 — Resource Requests and Limits for Scheduling

```bash
# Requests: minimum resources guaranteed; used by scheduler for placement
# Limits: maximum resources allowed; enforced at runtime by cgroups

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: resource-pod
spec:
  containers:
  - name: app
    image: nginx:alpine
    resources:
      requests:
        cpu: 500m           # 0.5 CPU cores requested
        memory: 256Mi       # 256 MiB memory requested
      limits:
        cpu: "1"            # 1 CPU core maximum
        memory: 512Mi       # 512 MiB memory maximum
EOF

# View resource allocation
kubectl describe node worker01 | grep -A 20 'Allocated resources'
# Shows how much of the node's capacity is reserved by requests

# Create an unschedulable pod (requests exceed node capacity)
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: too-big-pod
spec:
  containers:
  - name: app
    image: nginx:alpine
    resources:
      requests:
        cpu: "64"           # 64 CPU cores — no node has this
        memory: 256Gi       # 256 GiB RAM
EOF

kubectl get pod too-big-pod
# STATUS: Pending

kubectl describe pod too-big-pod | grep -A 5 'Events:'
# Insufficient cpu, Insufficient memory
```

The scheduler only looks at resource **requests** for placement decisions, not limits. If a pod's requests exceed available allocatable capacity on all nodes, it stays Pending. Limits are enforced by the container runtime (cgroups) at runtime.

---

## Step 9 — LimitRange and ResourceQuota

```bash
# LimitRange sets default requests/limits for pods that don't specify them
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: default
spec:
  limits:
  - type: Container
    default:
      cpu: 200m
      memory: 256Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    max:
      cpu: "2"
      memory: 2Gi
    min:
      cpu: 50m
      memory: 64Mi
EOF

# ResourceQuota limits total resources in a namespace
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: default
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 4Gi
    limits.cpu: "8"
    limits.memory: 8Gi
    pods: "20"
EOF

kubectl describe resourcequota compute-quota
kubectl describe limitrange default-limits
```

`LimitRange` sets per-pod defaults and bounds; `ResourceQuota` sets namespace-wide totals. Together they prevent resource hogging and ensure fair sharing in multi-tenant clusters.

---

## Step 10 — Clean Up

```bash
# Remove taints
kubectl taint node worker01 gpu=true:NoSchedule- 2>/dev/null
kubectl taint node worker01 maintenance=true:NoExecute- 2>/dev/null
kubectl taint node controlplane dedicated=control-plane:NoSchedule- 2>/dev/null

# Remove labels
kubectl label node worker01 disk- region- environment- 2>/dev/null
kubectl label node controlplane disk- region- environment- 2>/dev/null

# Delete pods and resources
kubectl delete pod ssd-pod nvme-pod affinity-required affinity-preferred \
  affinity-combined gpu-pod tolerant-pod workload-1 workload-2 \
  graceful-pod resource-pod too-big-pod 2>/dev/null
kubectl delete limitrange default-limits
kubectl delete resourcequota compute-quota
```

---

## Free online tools
- **Kubernetes Docs — Scheduling**: https://kubernetes.io/docs/concepts/scheduling-eviction/
- **Kubernetes Docs — Assign Pods to Nodes**: https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes-using-node-affinity/
- **Kubernetes Docs — Taints and Tolerations**: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/
- **killer.sh** — CKA mock exam: https://killer.sh

---

## What you learned
- `nodeSelector` is the simplest placement constraint — exact label match; only supports equality
- Node affinity `requiredDuringScheduling` is a hard constraint (pod stays Pending if no match)
- Node affinity `preferredDuringScheduling` is a soft constraint with weighted preference scoring
- Multiple `matchExpressions` in one term are ANDed; multiple `nodeSelectorTerms` are ORed
- Taints repel pods from nodes; `NoSchedule`, `PreferNoSchedule`, and `NoExecute` are the three effects
- `NoExecute` taints evict running pods without matching tolerations
- `tolerationSeconds` on `NoExecute` tolerations provides a grace period before eviction
- Tolerations allow pods to bypass taints; `operator: Exists` without a key tolerates any taint
- Resource **requests** are used by the scheduler for placement; **limits** are enforced at runtime
- `LimitRange` sets per-container defaults; `ResourceQuota` caps namespace-wide resource totals
