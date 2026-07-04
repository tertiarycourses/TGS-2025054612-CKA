# Step 2 — Create a PV

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
