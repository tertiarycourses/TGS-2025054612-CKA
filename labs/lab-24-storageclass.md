# Lab 24 — StorageClass and Dynamic Provisioning

Static PVs don't scale. Dynamic provisioning uses a StorageClass and a CSI provisioner to create PVs automatically when a PVC is submitted. CKA 2026 tests creating StorageClasses, marking a default class, dynamic PVC binding, and StatefulSet `volumeClaimTemplates`.

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- `kubectl` (pre-installed on Killercoda)
- `local-path-provisioner` (installed in Step 2 if not present)
- `postgres:16-alpine` image (pulled automatically)

---

## Step 1 — Check existing StorageClasses

```bash
kubectl get storageclass
kubectl get sc
```

Killercoda may already have `local-path`. If `(default)` appears next to it, skip Step 2 and 3.

---

## Step 2 — Install local-path-provisioner

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl -n local-path-storage rollout status deploy/local-path-provisioner --timeout=120s
kubectl get storageclass
```

---

## Step 3 — Mark it as the default StorageClass

```bash
kubectl patch storageclass local-path \
  -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl get sc
```

The `(default)` marker means PVCs without `storageClassName` use this class automatically.

---

## Step 4 — Create a PVC without specifying a class (uses default)

```bash
cat > data-pvc.yaml <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 200Mi
EOF
kubectl apply -f data-pvc.yaml
kubectl get pvc data-pvc
kubectl get pv
```

A PV appears automatically — the provisioner reacted to the PVC. Status goes `Pending` → `Bound`.

---

## Step 5 — StatefulSet with volumeClaimTemplates

```bash
cat > sts.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: db-headless
spec:
  clusterIP: None
  selector:
    app: db
  ports:
  - port: 5432
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: db
spec:
  serviceName: db-headless
  replicas: 2
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
      - name: pg
        image: postgres:16-alpine
        env:
        - name: POSTGRES_PASSWORD
          value: changeme
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
          subPath: pg
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 500Mi
EOF
kubectl apply -f sts.yaml
kubectl rollout status statefulset/db
kubectl get pvc
kubectl get pv
```

Each replica gets its own PVC: `data-db-0`, `data-db-1`. This is the key difference from Deployments — StatefulSet PVCs are not shared.

---

## Step 6 — Verify data persistence across Pod restarts

```bash
kubectl exec db-0 -- psql -U postgres -c \
  "create table t(x int); insert into t values(42);"
kubectl delete pod db-0
kubectl wait --for=condition=Ready pod/db-0 --timeout=120s
kubectl exec db-0 -- psql -U postgres -c "select * from t;"
```

Expected: row with `42` — data survived the Pod restart.

---

## Step 7 — Clean up

```bash
kubectl delete statefulset db
kubectl delete svc db-headless
kubectl delete pvc -l app=db
kubectl delete pvc data-pvc
```

PVCs from `volumeClaimTemplates` are **not** auto-deleted when the StatefulSet is removed — always clean them up explicitly.

---

## Free online tools

- **StorageClass docs**: https://kubernetes.io/docs/concepts/storage/storage-classes/
- **Dynamic provisioning**: https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/
- **local-path-provisioner**: https://github.com/rancher/local-path-provisioner
- **killer.sh** — CKA mock exam: https://killer.sh
- **Kubernetes docs** (allowed in CKA exam): https://kubernetes.io/docs/

---

## What you learned

- StorageClass + provisioner = automatic PV creation on PVC submission.
- The `is-default-class: "true"` annotation makes PVCs without `storageClassName` use this class.
- `volumeClaimTemplates` in a StatefulSet gives each replica its own independent PVC.
- StatefulSet PVCs survive StatefulSet deletion — clean them up manually.
