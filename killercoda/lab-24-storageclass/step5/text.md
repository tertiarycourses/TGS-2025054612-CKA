# Step 5 — Mount it in a StatefulSet

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata: { name: db-headless }
spec:
  clusterIP: None
  selector: { app: db }
  ports: [{ port: 5432 }]
---
apiVersion: apps/v1
kind: StatefulSet
metadata: { name: db }
spec:
  serviceName: db-headless
  replicas: 2
  selector: { matchLabels: { app: db } }
  template:
    metadata: { labels: { app: db } }
    spec:
      containers:
      - name: pg
        image: postgres:16-alpine
        env:
        - { name: POSTGRES_PASSWORD, value: changeme }
        volumeMounts:
        - { name: data, mountPath: /var/lib/postgresql/data, subPath: pg }
  volumeClaimTemplates:
  - metadata: { name: data }
    spec:
      accessModes: [ReadWriteOnce]
      resources: { requests: { storage: 500Mi } }
EOF
kubectl rollout status statefulset/db
kubectl get pvc
kubectl get pv
```

Each replica gets its **own** PVC and PV — `data-db-0`, `data-db-1`.
