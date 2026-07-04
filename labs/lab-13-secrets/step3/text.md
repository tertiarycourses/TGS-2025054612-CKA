# Step 3 — Consume as a mounted file

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: sec-file }
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh","-c","ls /etc/db; cat /etc/db/username; echo; sleep 3600"]
    volumeMounts:
    - { name: creds, mountPath: /etc/db, readOnly: true }
  volumes:
  - name: creds
    secret: { secretName: db-creds, defaultMode: 0400 }
EOF
kubectl wait --for=condition=Ready pod/sec-file --timeout=60s
kubectl logs sec-file
```

Files mounted from a Secret are tmpfs — never written to disk on the node.
