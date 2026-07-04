# Step 5 — Persistence test

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
