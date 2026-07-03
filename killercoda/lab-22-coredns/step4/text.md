# Step 4 — Pod records (headless services)

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata: { name: web-h }
spec:
  clusterIP: None
  selector: { app: web }
  ports: [{ port: 80 }]
EOF
kubectl exec dnsdebug -- dig +short web-h.default.svc.cluster.local
```

A headless Service returns the **pod IPs** directly — no virtual ClusterIP.
