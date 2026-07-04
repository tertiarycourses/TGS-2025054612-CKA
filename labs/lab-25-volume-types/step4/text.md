# Step 4 — projected (combine many sources)

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: projected-demo }
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh","-c","ls -la /proj; cat /proj/greeting /proj/token; sleep 3600"]
    volumeMounts: [{ name: all, mountPath: /proj }]
  volumes:
  - name: all
    projected:
      sources:
      - configMap: { name: demo-cfg }
      - secret:    { name: demo-sec }
EOF
kubectl wait --for=condition=Ready pod/projected-demo --timeout=60s
kubectl logs projected-demo
```

A single mount point exposes keys from multiple ConfigMaps/Secrets/serviceAccountTokens.
