# Lab 23 — PersistentVolume and PersistentVolumeClaim

A PersistentVolume (PV) is a cluster-level storage resource. A PersistentVolumeClaim (PVC) is a Pod's request for that storage. CKA 2026 tests static provisioning, PV/PVC binding rules, access modes, reclaim policies, and the fact that PVCs outlive Pods.

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- `kubectl` (pre-installed on Killercoda)
- `nginx` image (pulled automatically)

---

## Step 1 — Prepare a host directory

```bash
sudo mkdir -p /mnt/data
echo "hello from host" | sudo tee /mnt/data/index.html
```

---

## Step 2 — Create a PersistentVolume (static provisioning)

```bash
cat > pv.yaml <<'EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-host
spec:
  capacity:
    storage: 1Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /mnt/data
EOF
kubectl apply -f pv.yaml
kubectl get pv pv-host
```

Access modes (memorise for the exam):
- `ReadWriteOnce (RWO)` — one node, read-write
- `ReadOnlyMany (ROX)` — many nodes, read-only
- `ReadWriteMany (RWX)` — many nodes, read-write (needs NFS/CephFS)
- `ReadWriteOncePod (RWOP)` — one Pod, read-write (Kubernetes v1.22+)

Reclaim policies:
- `Retain` — keep data after PVC deletion; admin must clean up manually
- `Delete` — remove underlying storage (default for dynamic provisioning)

---

## Step 3 — Create a PersistentVolumeClaim

```bash
cat > pvc.yaml <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-host
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: manual
  resources:
    requests:
      storage: 500Mi
EOF
kubectl apply -f pvc.yaml
kubectl get pvc pvc-host
kubectl get pv pv-host
```

The PVC binds because: same `storageClassName`, PV capacity ≥ PVC request, and matching access mode. Status changes from `Available` → `Bound`.

---

## Step 4 — Mount the PVC in a Pod

```bash
cat > pod.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: web
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: data
      mountPath: /usr/share/nginx/html
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: pvc-host
EOF
kubectl apply -f pod.yaml
kubectl wait --for=condition=Ready pod/web --timeout=60s
kubectl exec web -- curl -s localhost
```

Expected: `hello from host`

---

## Step 5 — Verify persistence across Pod restarts

```bash
kubectl exec web -- sh -c 'echo "written by pod" > /usr/share/nginx/html/index.html'
kubectl delete pod web
kubectl apply -f pod.yaml
kubectl wait --for=condition=Ready pod/web --timeout=60s
kubectl exec web -- curl -s localhost
```

Expected: `written by pod` — PVCs and their data survive Pod deletion.

---

## Step 6 — Observe Retain reclaim policy

```bash
kubectl delete pod web
kubectl delete pvc pvc-host
kubectl get pv pv-host
```

With `persistentVolumeReclaimPolicy: Retain`, the PV status becomes `Released` (not deleted). To reuse it, remove `spec.claimRef` from the PV:

```bash
kubectl patch pv pv-host --type=json \
  -p='[{"op":"remove","path":"/spec/claimRef"}]'
kubectl get pv pv-host
```

Status returns to `Available`.

---

## Step 7 — Clean up

```bash
kubectl delete pv pv-host
sudo rm -rf /mnt/data
```

---

## Free online tools

- **PV/PVC docs**: https://kubernetes.io/docs/concepts/storage/persistent-volumes/
- **Access modes reference**: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes
- **killer.sh** — CKA mock exam: https://killer.sh
- **Kubernetes docs** (allowed in CKA exam): https://kubernetes.io/docs/

---

## What you learned

- PV/PVC binding requires matching: `storageClassName`, `accessModes`, and sufficient capacity.
- Four access modes: RWO, ROX, RWX, RWOP — know when each applies.
- `Retain` policy keeps data after PVC deletion; admin must re-enable the PV manually.
- PVCs outlive Pods — data persists across restarts and rescheduling.
