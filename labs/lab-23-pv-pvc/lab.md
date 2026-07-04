# Lab 23 — PersistentVolume and PersistentVolumeClaim

A PersistentVolume (PV) is a piece of storage in the cluster. A PersistentVolumeClaim (PVC) is a pod's request for storage. In this lab you statically provision a `hostPath` PV, claim it, mount it, and explore access modes and reclaim policies.

**Lab environment:** [Play with Kubernetes](https://killercoda.com/playgrounds/course/kubernetes-playgrounds/two-node)
---

## Step 1 — Prepare a host directory

```bash
sudo mkdir -p /mnt/data
echo "hello from host" | sudo tee /mnt/data/index.html
```

---

## Step 2 — Create a PV

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-host
spec:
  capacity: { storage: 1Gi }
  accessModes: [ReadWriteOnce]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath: { path: /mnt/data }
EOF
kubectl get pv pv-host
```

Access modes:
- **ReadWriteOnce (RWO)** — one node, read-write
- **ReadOnlyMany (ROX)** — many nodes, read-only
- **ReadWriteMany (RWX)** — many nodes, read-write (needs NFS/CephFS-class storage)
- **ReadWriteOncePod (RWOP)** — one pod, read-write

Reclaim policies:
- **Retain** — keep data after PVC deletion (manual cleanup)
- **Delete** — remove the volume (dynamic provisioning default)
- **Recycle** — deprecated

---

## Step 3 — Create a PVC

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata: { name: pvc-host }
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: manual
  resources: { requests: { storage: 500Mi } }
EOF
kubectl get pvc pvc-host
kubectl get pv pv-host
```

The PVC binds to the PV because both have `storageClassName: manual` and the PV size satisfies the request.

---

## Step 4 — Mount in a Pod

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: web }
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - { name: data, mountPath: /usr/share/nginx/html }
  volumes:
  - name: data
    persistentVolumeClaim: { claimName: pvc-host }
EOF
kubectl wait --for=condition=Ready pod/web --timeout=60s
kubectl exec web -- curl -s localhost
```

You should see "hello from host".

---

## Step 5 — Persistence test

```bash
kubectl exec web -- sh -c 'echo "from pod" > /usr/share/nginx/html/index.html'
kubectl delete pod web
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata: { name: web }
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - { name: data, mountPath: /usr/share/nginx/html }
  volumes:
  - name: data
    persistentVolumeClaim: { claimName: pvc-host }
EOF
kubectl wait --for=condition=Ready pod/web --timeout=60s
kubectl exec web -- curl -s localhost
```

The new pod sees the previous pod's data — PVCs survive pod restarts.

---

## Step 6 — Reclaim behavior

```bash
kubectl delete pod web
kubectl delete pvc pvc-host
kubectl get pv pv-host
```

The PV stays in `Released` (Retain policy). To re-use it, edit and clear `spec.claimRef`, or change reclaim policy to `Delete`.

---

## Step 7 — Cleanup

```bash
kubectl delete pv pv-host
sudo rm -rf /mnt/data
```

---

## What you learned
- PV/PVC binding rules: storage class + size + access mode match.
- The four access modes and three reclaim policies.
- PVCs outlive pods.
