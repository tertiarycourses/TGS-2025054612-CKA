# Step 3 — Create a PVC

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
