# Step 4 — Create a PVC without specifying a class

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
