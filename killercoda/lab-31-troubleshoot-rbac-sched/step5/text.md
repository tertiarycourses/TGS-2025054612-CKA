# Step 5 — Pending due to resources

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
