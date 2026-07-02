# Practicum 2 — Workloads & Scheduling (Domain 2)

> **Day 2 assessment  ·  Time allowed: 45 minutes**  
> Platform: [Killercoda Kubernetes Playground](https://killercoda.com/playgrounds/scenario/kubernetes)

---

## Task 1 — Deploy and roll out an application (10 pts)

1. Create a **Deployment** named `frontend` in namespace `prod` using image `nginx:1.24`, with **3 replicas**.
2. Expose it as a **ClusterIP Service** on port **80**.
3. Update the image to `nginx:1.25` and verify the rolling rollout succeeds (`rollout status`).
4. Roll back to the previous revision with `rollout undo`.

**Verify:** `kubectl rollout history deployment/frontend -n prod` shows 2 revisions.

---

## Task 2 — ConfigMap and Secret injection (10 pts)

1. Create a **ConfigMap** `app-config` in namespace `prod` with key `LOG_LEVEL=info` and `APP_ENV=production`.
2. Create a **Secret** `db-creds` in namespace `prod` with key `DB_PASSWORD=s3cr3t`.
3. Create a Pod named `app-pod` that injects **all keys** from `app-config` using `envFrom`, and mounts `db-creds` as a file at `/etc/db/password` with `defaultMode: 0400`.

**Verify:** `kubectl exec app-pod -n prod -- env | grep LOG_LEVEL` shows `LOG_LEVEL=info`.

---

## Task 3 — Horizontal Pod Autoscaler (5 pts)

1. Ensure `metrics-server` is running in `kube-system` (apply the manifest if needed, add `--kubelet-insecure-tls`).
2. Create an HPA for the `frontend` Deployment targeting **50% CPU** utilisation, min replicas **2**, max replicas **6**.
3. Generate load with a busybox pod running `while true; do wget -q -O- http://<frontend-svc>; done`.

**Verify:** `kubectl get hpa -n prod` shows the HPA scaling up replicas.

---

## Task 4 — Pod Scheduling (5 pts)

1. Label the control-plane node: `kubectl label node <cp> zone=cp`.
2. Create a Pod `zone-pod` that uses **nodeAffinity** (required) to schedule only on nodes with label `zone=cp`.
3. Create another Pod `tolerate-pod` that tolerates the `node-role.kubernetes.io/control-plane:NoSchedule` taint.

**Verify:** Both pods are `Running` on the control-plane node.
