# Step 5 — StatefulSet (stable identity + storage)

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata: { name: web-headless }
spec:
  clusterIP: None
  selector: { app: web-ss }
  ports: [{ port: 80 }]
---
apiVersion: apps/v1
kind: StatefulSet
metadata: { name: web-ss }
spec:
  serviceName: web-headless
  replicas: 3
  selector: { matchLabels: { app: web-ss } }
  template:
    metadata: { labels: { app: web-ss } }
    spec:
      containers:
      - name: nginx
        image: nginx
        ports: [{ containerPort: 80 }]
EOF
kubectl rollout status statefulset/web-ss
kubectl get pods -l app=web-ss
```

Pods are named `web-ss-0`, `web-ss-1`, `web-ss-2` — stable identities. The headless Service gives each pod a DNS A record: `web-ss-0.web-headless.default.svc.cluster.local`.
