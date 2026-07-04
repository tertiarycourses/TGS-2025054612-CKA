# Step 4 — Mount in a Pod

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
