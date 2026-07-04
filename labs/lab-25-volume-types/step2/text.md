# Step 2 — hostPath (node directory)

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: hostpath-demo }
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh","-c","ls /host/etc/hostname; cat /host/etc/hostname; sleep 3600"]
    volumeMounts: [{ name: etc, mountPath: /host/etc, readOnly: true }]
  volumes:
  - name: etc
    hostPath: { path: /etc, type: Directory }
EOF
kubectl wait --for=condition=Ready pod/hostpath-demo --timeout=60s
kubectl logs hostpath-demo
```

⚠️ `hostPath` couples the pod to a specific node and is a security risk — admission controllers usually restrict it.
