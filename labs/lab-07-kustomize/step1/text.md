# Step 1 — Create the base

```bash
mkdir -p kustom/base
cat > kustom/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 1
  selector: { matchLabels: { app: web } }
  template:
    metadata: { labels: { app: web } }
    spec:
      containers:
      - name: web
        image: nginx:1.25
        ports: [{ containerPort: 80 }]
EOF
cat > kustom/base/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata: { name: web }
spec:
  selector: { app: web }
  ports: [{ port: 80, targetPort: 80 }]
EOF
cat > kustom/base/kustomization.yaml <<'EOF'
resources:
  - deployment.yaml
  - service.yaml
commonLabels:
  app: web
EOF
```
