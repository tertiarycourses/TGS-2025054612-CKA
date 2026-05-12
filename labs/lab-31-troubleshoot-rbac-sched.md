# Lab 31 — Troubleshoot RBAC and Scheduling Failures

Two more high-frequency exam scenarios: a ServiceAccount that can't do what it needs, and a Pod that stays `Pending` because the scheduler refuses to place it.

Use the **Kubernetes playground**: https://killercoda.com/playgrounds/scenario/kubernetes

---

## Part A — RBAC

### Step 1 — Create a broken setup

```bash
kubectl create ns app
kubectl -n app create sa worker
kubectl -n app run worker-pod --image=bitnami/kubectl --serviceaccount=worker \
  --command -- sleep 3600
kubectl -n app wait --for=condition=Ready pod/worker-pod --timeout=60s

kubectl -n app exec worker-pod -- kubectl get pods
# Forbidden
```

### Step 2 — Diagnose with `auth can-i`

```bash
kubectl -n app auth can-i list pods --as=system:serviceaccount:app:worker
kubectl -n app auth can-i list pods --as=system:serviceaccount:app:worker -v=6 2>&1 | grep -i forbidden
```

### Step 3 — Grant minimal access

```bash
kubectl -n app create role pod-reader --verb=get,list,watch --resource=pods
kubectl -n app create rolebinding worker-reader --role=pod-reader --serviceaccount=app:worker
kubectl -n app exec worker-pod -- kubectl get pods
```

### Step 4 — Wrong scope (common trap)

```bash
kubectl -n app exec worker-pod -- kubectl get nodes
# still Forbidden
```

Nodes are cluster-scoped → need a ClusterRoleBinding, not a RoleBinding:

```bash
kubectl create clusterrole node-reader --verb=get,list,watch --resource=nodes
kubectl create clusterrolebinding worker-nodes --clusterrole=node-reader --serviceaccount=app:worker
kubectl -n app exec worker-pod -- kubectl get nodes
```

---

## Part B — Scheduling failures

### Step 5 — Pending due to resources

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: hungry, namespace: app }
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests: { cpu: "100", memory: "100Gi" }
EOF
kubectl -n app get pod hungry
kubectl -n app describe pod hungry | tail -15
```

You'll see `0/N nodes available: Insufficient cpu/memory`.

Fix:

```bash
kubectl -n app delete pod hungry
```

### Step 6 — Pending due to taint

```bash
NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
kubectl taint node $NODE dedicated=critical:NoSchedule
kubectl -n app run untol --image=nginx
kubectl -n app describe pod untol | tail -10
```

`untolerated taint {dedicated: critical}`.

Fix:

```bash
kubectl taint node $NODE dedicated-
```

### Step 7 — Pending due to nodeSelector

```bash
kubectl -n app run picky --image=nginx \
  --overrides='{"spec":{"nodeSelector":{"zone":"never"}}}'
kubectl -n app describe pod picky | tail -10
```

`didn't match Pod's node affinity/selector`. Fix the label or the selector.

### Step 8 — Cleanup

```bash
kubectl delete ns app
kubectl delete clusterrole node-reader
kubectl delete clusterrolebinding worker-nodes
```

---

## Triage cheat sheet

| Symptom                                | First command                                                   |
|----------------------------------------|------------------------------------------------------------------|
| `forbidden`                            | `kubectl auth can-i <verb> <resource> --as=<sa>`                 |
| Pod `Pending`                          | `kubectl describe pod <name>` (read **Events**)                  |
| `Insufficient cpu/memory`              | `kubectl top nodes`, lower `resources.requests`                  |
| `untolerated taint`                    | `kubectl describe node | grep Taints`, add toleration or remove taint |
| `didn't match Pod's node affinity`     | Check labels: `kubectl get nodes --show-labels`                  |
| `pod has unbound immediate PVCs`       | `kubectl get pvc` → make sure StorageClass exists                |

---

## What you learned
- Use `kubectl auth can-i --as=` to confirm RBAC outcomes before deployment.
- `describe pod` Events tells you exactly why scheduling failed.
- Role/RoleBinding for namespaced resources; ClusterRole/ClusterRoleBinding for cluster-scoped.
