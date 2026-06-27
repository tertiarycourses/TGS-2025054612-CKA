# Lab 31 — Troubleshoot RBAC and Scheduling Failures

CKA 2026 closes with two of the most common exam question types: a `403 Forbidden` error caused by a missing ClusterRoleBinding, and a Pod stuck in `Pending` due to a scheduling constraint. This lab covers the full diagnosis-and-fix flow for both.

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- `kubectl` (pre-installed on Killercoda)
- `nginx` image (pre-pulled on Killercoda)

---

## Step 1 — Set exam aliases

```bash
alias k=kubectl
```

---

## Part A: RBAC Troubleshooting

## Step 2 — Create a ServiceAccount and deploy a Pod

```bash
k create serviceaccount dev-sa
cat > sa-pod.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: dev-pod
spec:
  serviceAccountName: dev-sa
  containers:
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ["sleep", "3600"]
EOF
k apply -f sa-pod.yaml
k wait --for=condition=Ready pod/dev-pod --timeout=60s
```

---

## Step 3 — Test access: expect 403

```bash
k exec dev-pod -- kubectl get pods 2>&1
```

Expected: `Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:default:dev-sa" cannot list resource "pods"`

---

## Step 4 — Diagnose with auth can-i

```bash
k auth can-i list pods --as=system:serviceaccount:default:dev-sa
k auth can-i list pods --as=system:serviceaccount:default:dev-sa -n default
```

Both return `no`. This is the exam-day tool to check effective permissions without needing to hit the API.

---

## Step 5 — Fix: create Role and RoleBinding

```bash
k create role pod-reader \
  --verb=get,list,watch \
  --resource=pods
k create rolebinding dev-sa-pod-reader \
  --role=pod-reader \
  --serviceaccount=default:dev-sa
k auth can-i list pods --as=system:serviceaccount:default:dev-sa
```

Expected: `yes`

```bash
k exec dev-pod -- kubectl get pods
```

---

## Step 6 — ClusterRole vs Role

```bash
k auth can-i list pods --as=system:serviceaccount:default:dev-sa --all-namespaces
```

Returns `no` — RoleBinding only covers the `default` namespace. For cluster-wide access:

```bash
k create clusterrolebinding dev-sa-cluster-reader \
  --clusterrole=view \
  --serviceaccount=default:dev-sa
k auth can-i list pods --as=system:serviceaccount:default:dev-sa --all-namespaces
```

---

## Part B: Scheduling Troubleshooting

## Step 7 — Pod stuck Pending due to missing node label

```bash
cat > pending-pod.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: gpu-pod
spec:
  nodeSelector:
    hardware: gpu
  containers:
  - name: app
    image: nginx
EOF
k apply -f pending-pod.yaml
k get pod gpu-pod
k describe pod gpu-pod | grep -A5 Events
```

Events show: `0/1 nodes are available: 1 node(s) didn't match Pod's node affinity/selector.`

---

## Step 8 — Fix: label the node

```bash
NODE=$(k get nodes -o jsonpath='{.items[0].metadata.name}')
k label node $NODE hardware=gpu
k get pod gpu-pod
```

Pod transitions `Pending` → `Running`.

---

## Step 9 — Pod stuck Pending due to insufficient resources

```bash
cat > hungry-pod.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: hungry-pod
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: "100"
        memory: "100Gi"
EOF
k apply -f hungry-pod.yaml
k describe pod hungry-pod | grep -A5 Events
```

Events: `Insufficient cpu`, `Insufficient memory`.

Diagnosis: check actual node capacity:

```bash
k describe nodes | grep -A5 "Allocatable:"
```

Fix: reduce resource requests to realistic values:

```bash
k delete pod hungry-pod
cat > hungry-pod-fixed.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: hungry-pod
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
EOF
k apply -f hungry-pod-fixed.yaml
k get pod hungry-pod
```

---

## Step 10 — Pod stuck Pending due to taint

```bash
k taint node $NODE env=prod:NoSchedule
cat > plain-pod.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: plain-pod
spec:
  containers:
  - name: app
    image: nginx
EOF
k apply -f plain-pod.yaml
k describe pod plain-pod | grep -A5 Events
```

Events: `1 node(s) had untolerated taint {env: prod}.`

Fix: add a toleration:

```bash
k delete pod plain-pod
cat > tolerated-pod.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: plain-pod
spec:
  tolerations:
  - key: env
    value: prod
    effect: NoSchedule
  containers:
  - name: app
    image: nginx
EOF
k apply -f tolerated-pod.yaml
k get pod plain-pod
```

---

## Step 11 — Scheduling triage reference

| Symptom in Events | Root cause | Fix |
|-------------------|-----------|-----|
| `node(s) didn't match node affinity/selector` | `nodeSelector` or `nodeAffinity` label missing | Label the node |
| `Insufficient cpu/memory` | Request > allocatable | Lower requests or add nodes |
| `had untolerated taint` | Node tainted, Pod has no toleration | Add `tolerations` to Pod spec |
| `0/N nodes are available` | All nodes unschedulable | Check taints, labels, cordons |
| `Forbidden: pods` | ServiceAccount missing RBAC | Create Role + RoleBinding |

---

## Step 12 — Clean up

```bash
k delete pod dev-pod gpu-pod hungry-pod plain-pod --force --grace-period=0 2>/dev/null || true
k delete rolebinding dev-sa-pod-reader
k delete clusterrolebinding dev-sa-cluster-reader
k delete role pod-reader
k delete sa dev-sa
k taint node $NODE env=prod:NoSchedule-
k label node $NODE hardware-
```

---

## Free online tools

- **RBAC docs**: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- **Scheduling docs**: https://kubernetes.io/docs/concepts/scheduling-eviction/
- **Taints and Tolerations**: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/
- **kubectl auth can-i**: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_auth/kubectl_auth_can-i/
- **killer.sh** — CKA mock exam: https://killer.sh
- **Kubernetes docs** (allowed in CKA exam): https://kubernetes.io/docs/

---

## What you learned

- `kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<ns>:<sa>` is the fastest RBAC debug tool.
- `Forbidden` errors name the exact SA and resource — read the error message first.
- `kubectl describe pod` → Events section reveals all scheduling failures.
- Three Pending causes: missing node label, insufficient resources, untolerated taint.
- Remove a taint with a trailing `-`: `kubectl taint node <name> <key>:<effect>-`.
