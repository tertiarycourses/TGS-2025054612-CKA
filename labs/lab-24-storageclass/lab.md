# Lab 24 — StorageClass and Dynamic Provisioning

Static PVs don't scale. With dynamic provisioning, a StorageClass + CSI driver creates a PV on demand when a PVC is submitted. In this lab you install the local-path-provisioner, create a default StorageClass, and watch a PVC trigger PV creation.

**Lab environment:** [KillerCoda](https://killercoda.com/tertiary-labs-cka/course/killercoda/lab-24-storageclass)
---

## Step 1 — Check existing storage classes

```bash
kubectl get storageclass
```

On Killercoda you may already have a `local-path` StorageClass. If yes, skip Step 2.

---

## Step 2 — Install local-path-provisioner

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl -n local-path-storage rollout status deploy/local-path-provisioner --timeout=120s
kubectl get storageclass
```

---

## Step 3 — Mark it as default

```bash
kubectl patch storageclass local-path \
  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl get sc
```

The `(default)` marker appears next to `local-path`.

---

## Step 4 — Create a PVC without specifying a class

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata: { name: data-pvc }
spec:
  accessModes: [ReadWriteOnce]
  resources: { requests: { storage: 200Mi } }
EOF
kubectl get pvc
kubectl get pv
```

A PV appears automatically — that's the provisioner reacting to the PVC.

---

## Step 5 — Mount it in a StatefulSet

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata: { name: db-headless }
spec:
  clusterIP: None
  selector: { app: db }
  ports: [{ port: 5432 }]
---
apiVersion: apps/v1
kind: StatefulSet
metadata: { name: db }
spec:
  serviceName: db-headless
  replicas: 2
  selector: { matchLabels: { app: db } }
  template:
    metadata: { labels: { app: db } }
    spec:
      containers:
      - name: pg
        image: postgres:16-alpine
        env:
        - { name: POSTGRES_PASSWORD, value: changeme }
        volumeMounts:
        - { name: data, mountPath: /var/lib/postgresql/data, subPath: pg }
  volumeClaimTemplates:
  - metadata: { name: data }
    spec:
      accessModes: [ReadWriteOnce]
      resources: { requests: { storage: 500Mi } }
EOF
kubectl rollout status statefulset/db
kubectl get pvc
kubectl get pv
```

Each replica gets its **own** PVC and PV — `data-db-0`, `data-db-1`.

---

## Step 6 — Verify the volume lifecycle

```bash
kubectl exec db-0 -- psql -U postgres -c "create table t(x int); insert into t values(1);"
kubectl delete pod db-0
kubectl wait --for=condition=Ready pod/db-0 --timeout=120s
kubectl exec db-0 -- psql -U postgres -c "select * from t;"
```

Data survives the pod restart.

---

## Step 7 — Cleanup

```bash
kubectl delete statefulset db
kubectl delete svc db-headless
kubectl delete pvc -l app=db
kubectl delete pvc data-pvc
```

PVCs created by `volumeClaimTemplates` are **not** auto-deleted; clean them up explicitly.

---

## What you learned
- StorageClass + provisioner = dynamic PV creation.
- The default-class annotation lets PVCs omit `storageClassName`.
- `volumeClaimTemplates` give each StatefulSet replica its own persistent volume.
