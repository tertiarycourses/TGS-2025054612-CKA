# Lab 7 — Kustomize: Base + Overlays, namePrefix, images, patches, kubectl apply -k

Kustomize is built into kubectl (no separate install needed) and provides template-free customization of Kubernetes manifests. It uses a base layer of YAML files that overlays modify without duplicating files — making it ideal for managing dev/staging/production environments from a single source. The CKA exam tests `kubectl apply -k` and expects you to understand base/overlay structure, namePrefix, image overrides, and strategic merge patches. Kustomize is officially allowed via kubernetes.io/docs during the exam.

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- kubectl v1.35 with built-in kustomize (pre-installed)

---

## Step 1 — Verify Kustomize is Built into kubectl

```bash
# Kustomize is embedded in kubectl — no separate install needed
kubectl version --client | grep -i kustomize
# or
kubectl kustomize --help

# Verify the kustomize version bundled with kubectl
kubectl version --client -o yaml | grep -i kustomize

# You can also install the standalone kustomize binary for advanced use:
# curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
# mv kustomize /usr/local/bin/
# kustomize version
```

`kubectl apply -k` and `kubectl kustomize` use the embedded kustomize engine. The standalone `kustomize` binary may have a newer version but the built-in version is sufficient for CKA exam tasks.

---

## Step 2 — Create the Base Layer

```bash
# Create directory structure
mkdir -p ~/kustomize-lab/base
mkdir -p ~/kustomize-lab/overlays/dev
mkdir -p ~/kustomize-lab/overlays/production

# Create base Deployment
cat <<'EOF' > ~/kustomize-lab/base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  labels:
    app: webapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: nginx:1.25
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
EOF

# Create base Service
cat <<'EOF' > ~/kustomize-lab/base/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp
spec:
  selector:
    app: webapp
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
```

The base layer contains the "default" configuration shared across all environments. Overlays will add environment-specific changes without modifying these base files.

---

## Step 3 — Create the Base kustomization.yaml

```bash
# Create the base kustomization.yaml
cat <<'EOF' > ~/kustomize-lab/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml

commonLabels:
  managed-by: kustomize
  app.kubernetes.io/part-of: webapp
EOF

# Preview what the base renders to
kubectl kustomize ~/kustomize-lab/base
```

`kustomization.yaml` is the entry point for every kustomize layer. The `resources` field lists which YAML files to include. `commonLabels` adds labels to all resources in this layer.

---

## Step 4 — Create the Dev Overlay

```bash
# Dev overlay: adds 'dev-' prefix, scales to 1 replica
cat <<'EOF' > ~/kustomize-lab/overlays/dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# Point to the base layer
bases:
  - ../../base

# Add a prefix to all resource names in this overlay
namePrefix: dev-

# Add dev-specific labels
commonLabels:
  environment: dev

# Override the namespace
namespace: dev

# Override the image tag for dev
images:
  - name: nginx
    newTag: "1.25-alpine"
EOF

# Preview dev overlay output
kubectl kustomize ~/kustomize-lab/overlays/dev
# Resources will be named 'dev-webapp' with namespace 'dev'
```

`namePrefix` automatically prepends a string to all resource names and cross-references (like selectors). This prevents naming conflicts when deploying the same base to multiple namespaces.

---

## Step 5 — Create the Production Overlay with Patches

```bash
# Production overlay: more replicas, different image, resource patch
cat <<'EOF' > ~/kustomize-lab/overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

bases:
  - ../../base

namePrefix: prod-
namespace: production

commonLabels:
  environment: production

# Override image for production
images:
  - name: nginx
    newName: nginx
    newTag: "1.27"

# Apply a strategic merge patch to increase replicas and resources
patches:
  - path: replica-patch.yaml
  - path: resource-patch.yaml
EOF

# Create the replica patch
cat <<'EOF' > ~/kustomize-lab/overlays/production/replica-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp  # Must match base resource name (before namePrefix)
spec:
  replicas: 3
EOF

# Create the resource limits patch
cat <<'EOF' > ~/kustomize-lab/overlays/production/resource-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  template:
    spec:
      containers:
      - name: webapp
        resources:
          requests:
            cpu: 250m
            memory: 256Mi
          limits:
            cpu: 1000m
            memory: 512Mi
EOF

# Preview production output
kubectl kustomize ~/kustomize-lab/overlays/production
```

Kustomize patches use strategic merge patch semantics — you only specify the fields you want to change; everything else is inherited from the base. The `name` in a patch must match the base resource name (before namePrefix is applied).

---

## Step 6 — Apply with kubectl apply -k

```bash
# Create namespaces first
kubectl create namespace dev
kubectl create namespace production

# Apply the dev overlay
kubectl apply -k ~/kustomize-lab/overlays/dev

# Apply the production overlay
kubectl apply -k ~/kustomize-lab/overlays/production

# Verify resources were created
kubectl get all -n dev
kubectl get all -n production

# Check that names got the prefix
kubectl get deployment -n dev
# NAME         READY   UP-TO-DATE   AVAILABLE
# dev-webapp   1/1     1            1

kubectl get deployment -n production
# NAME          READY   UP-TO-DATE   AVAILABLE
# prod-webapp   3/3     3            3
```

`kubectl apply -k <directory>` reads the `kustomization.yaml` in that directory and applies the rendered output. It's equivalent to running `kubectl kustomize | kubectl apply -f -`.

---

## Step 7 — Add a ConfigMap Generator

```bash
# Kustomize can generate ConfigMaps and Secrets from files or literals
cat <<'EOF' > ~/kustomize-lab/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml

commonLabels:
  managed-by: kustomize

# Generate a ConfigMap from literals
configMapGenerator:
  - name: webapp-config
    literals:
      - APP_ENV=base
      - LOG_LEVEL=info
      - MAX_CONNECTIONS=100

# Generated ConfigMaps get a hash suffix to force pod restarts on changes
# e.g., webapp-config-abc123
EOF

kubectl kustomize ~/kustomize-lab/base | grep -A 10 'ConfigMap'
```

ConfigMap generators add a content-hash suffix to the ConfigMap name. When the ConfigMap content changes, the hash changes, forcing Deployments that reference it to roll out new pods — preventing stale configuration.

---

## Step 8 — Use JSON Patch (RFC 6902)

```bash
# JSON patches allow precise targeting of fields
# Useful when strategic merge patch doesn't give enough control

cat <<'EOF' > ~/kustomize-lab/overlays/dev/json-patch.yaml
- op: replace
  path: /spec/template/spec/containers/0/image
  value: nginx:debug
- op: add
  path: /spec/template/spec/containers/0/env
  value:
    - name: DEBUG
      value: "true"
EOF

# Reference the JSON patch in kustomization.yaml
cat <<'EOF' >> ~/kustomize-lab/overlays/dev/kustomization.yaml

patches:
  - path: json-patch.yaml
    target:
      kind: Deployment
      name: webapp
EOF

kubectl kustomize ~/kustomize-lab/overlays/dev
```

JSON patch operations (`add`, `replace`, `remove`) provide surgical precision when you need to modify a specific array element or path that strategic merge patch cannot target cleanly.

---

## Step 9 — Preview and Diff Before Applying

```bash
# Render without applying (for review)
kubectl kustomize ~/kustomize-lab/overlays/production

# Diff against the current cluster state
kubectl diff -k ~/kustomize-lab/overlays/production

# The diff shows what would change if you ran apply -k
# + lines would be added, - lines would be removed
```

`kubectl diff -k` is extremely useful before applying changes to a production cluster. It shows exactly what will change without making any modifications.

---

## Step 10 — Directory Structure Summary

```bash
# View the complete directory structure
find ~/kustomize-lab -type f | sort

# Expected:
# ~/kustomize-lab/base/deployment.yaml
# ~/kustomize-lab/base/kustomization.yaml
# ~/kustomize-lab/base/service.yaml
# ~/kustomize-lab/overlays/dev/json-patch.yaml
# ~/kustomize-lab/overlays/dev/kustomization.yaml
# ~/kustomize-lab/overlays/production/kustomization.yaml
# ~/kustomize-lab/overlays/production/replica-patch.yaml
# ~/kustomize-lab/overlays/production/resource-patch.yaml

# Clean up
kubectl delete -k ~/kustomize-lab/overlays/dev
kubectl delete -k ~/kustomize-lab/overlays/production
kubectl delete namespace dev production
```

The base + overlays pattern keeps shared configuration in one place while allowing environment-specific customization without file duplication. Changes to the base automatically propagate to all overlays.

---

## Free online tools
- **Kubernetes Docs — Kustomize**: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/
- **Kustomize official site**: https://kustomize.io/
- **killer.sh** — CKA mock exam: https://killer.sh

---

## What you learned
- Kustomize is built into kubectl v1.14+ — use `kubectl apply -k` and `kubectl kustomize`
- The base layer holds shared configuration; overlays hold environment-specific customization
- `kustomization.yaml` is required in every directory — it lists resources and transformations
- `namePrefix` automatically prepends a string to all resource names in a layer
- `images:` overrides container image names and tags without editing base YAML files
- `patches:` with strategic merge patch syntax only requires you to specify fields that differ
- JSON patches (RFC 6902) provide surgical precision with `add`, `replace`, `remove` operations
- `configMapGenerator` creates ConfigMaps with content-hash suffixes for automatic pod restarts
- `kubectl diff -k` previews changes before applying — essential for safe production deployments
- `kubectl delete -k` removes all resources in a kustomization layer cleanly
