# Step 3 — Consume as environment variables

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: env-demo }
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh","-c","env | grep APP_; sleep 3600"]
    envFrom:
    - configMapRef: { name: app-config }
EOF
kubectl wait --for=condition=Ready pod/env-demo --timeout=60s
kubectl logs env-demo
```

You should see both `APP_ENV=prod` and `APP_TIER=backend`.
