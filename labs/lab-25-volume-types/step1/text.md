# Step 1 — emptyDir (scratch space, pod lifetime)

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: scratch }
spec:
  containers:
  - name: writer
    image: busybox
    command: ["sh","-c","echo hello > /data/file; sleep 3600"]
    volumeMounts: [{ name: tmp, mountPath: /data }]
  - name: reader
    image: busybox
    command: ["sh","-c","cat /data/file; sleep 3600"]
    volumeMounts: [{ name: tmp, mountPath: /data }]
  volumes:
  - name: tmp
    emptyDir: {}
EOF
kubectl wait --for=condition=Ready pod/scratch --timeout=60s
kubectl logs scratch -c reader
```

Two containers share `/data`. Deleting the pod deletes the volume.
