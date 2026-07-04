# Step 5 — Resource requests and limits

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: sized }
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests: { cpu: "100m", memory: "64Mi" }
      limits:   { cpu: "500m", memory: "128Mi" }
EOF
kubectl describe pod sized | grep -A3 Limits
```

The scheduler only places the pod on a node with enough **requested** CPU+memory free.
