# Step 4 — Consume as a mounted file

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: file-demo }
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh","-c","cat /etc/cfg/app.properties; sleep 3600"]
    volumeMounts:
    - { name: cfg, mountPath: /etc/cfg }
  volumes:
  - name: cfg
    configMap: { name: app-properties }
EOF
kubectl wait --for=condition=Ready pod/file-demo --timeout=60s
kubectl logs file-demo
```
