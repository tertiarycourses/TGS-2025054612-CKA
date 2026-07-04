# Step 4 — Pod anti-affinity (spread)

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata: { name: spread }
spec:
  replicas: 2
  selector: { matchLabels: { app: spread } }
  template:
    metadata: { labels: { app: spread } }
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels: { app: spread }
            topologyKey: kubernetes.io/hostname
      containers:
      - { name: app, image: nginx }
EOF
kubectl get pods -l app=spread -o wide
```

The two replicas land on different nodes (or one stays Pending if the cluster has only one node).
