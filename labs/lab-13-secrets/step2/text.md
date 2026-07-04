# Step 2 — Consume as env vars

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: sec-env }
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh","-c","echo user=$DB_USER pw=$DB_PASS; sleep 3600"]
    env:
    - name: DB_USER
      valueFrom: { secretKeyRef: { name: db-creds, key: username } }
    - name: DB_PASS
      valueFrom: { secretKeyRef: { name: db-creds, key: password } }
EOF
kubectl wait --for=condition=Ready pod/sec-env --timeout=60s
kubectl logs sec-env
```
