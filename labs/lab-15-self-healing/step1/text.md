# Step 1 — Liveness probe

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: live-demo }
spec:
  containers:
  - name: app
    image: busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm /tmp/healthy; sleep 600
    livenessProbe:
      exec: { command: ["cat","/tmp/healthy"] }
      initialDelaySeconds: 5
      periodSeconds: 5
EOF
kubectl get pod live-demo -w
```

After ~35 s the probe fails, kubelet restarts the container, `RESTARTS` counter increments.
