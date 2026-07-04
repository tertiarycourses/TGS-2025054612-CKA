# Lab 7 — Customize Manifests with Kustomize

Kustomize is the template-free overlay tool baked into `kubectl` (`kubectl apply -k`). In this lab you build a base nginx Deployment and two overlays (`dev`, `prod`) that change the replica count, image tag, and namespace without copying YAML.

**Lab environment:** *(link to be added)*
---

## Step 1 — Create the base

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

---

## Step 2 — Create the dev overlay

```bash
mkdir -p kustom/overlays/dev
cat > kustom/overlays/dev/kustomization.yaml <<'EOF'
namespace: web-dev
resources:
  - ../../base
patches:
  - target: { kind: Deployment, name: web }
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 1
images:
  - name: nginx
    newTag: "1.25"
EOF
```

---

## Step 3 — Create the prod overlay

```bash
mkdir -p kustom/overlays/prod
cat > kustom/overlays/prod/kustomization.yaml <<'EOF'
namespace: web-prod
resources:
  - ../../base
patches:
  - target: { kind: Deployment, name: web }
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 4
images:
  - name: nginx
    newTag: "1.27"
EOF
```

---

## Step 4 — Render and apply

```bash
kubectl create ns web-dev
kubectl create ns web-prod
kubectl kustomize kustom/overlays/dev | head -30
kubectl apply -k kustom/overlays/dev
kubectl apply -k kustom/overlays/prod
kubectl -n web-dev get deploy
kubectl -n web-prod get deploy
```

Notice both deployments come from the same base, but with different replicas and image tags.

---

## Step 5 — Use a strategic-merge patch

Replace the JSON6902 patch in `dev/kustomization.yaml` with a strategic patch:

```yaml
patches:
  - path: replica-patch.yaml
```

And `kustom/overlays/dev/replica-patch.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata: { name: web }
spec:
  replicas: 2
```

Re-apply with `kubectl apply -k kustom/overlays/dev` and watch the rollout.

---

## What you learned
- Base + overlay structure.
- JSON6902 vs strategic-merge patches.
- `kubectl kustomize` (render) vs `kubectl apply -k` (render + apply).
