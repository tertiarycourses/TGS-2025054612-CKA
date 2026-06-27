# Lab 6 — Helm: Install, Upgrade, Rollback, --set, -f values.yaml, helm template

Helm is the package manager for Kubernetes and is explicitly allowed as a reference during the CKA exam (helm.sh/docs). This lab covers the complete Helm workflow: adding repos, installing charts, overriding values with `--set` and `-f`, upgrading releases, performing rollbacks, and using `helm template` to render manifests without installing them. Helm is widely used for deploying third-party software (ingress controllers, cert-manager, monitoring stacks) that appear in CKA exam scenarios.

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- helm v3 (install command below)
- kubectl v1.35 (pre-installed)

---

## Step 1 — Install Helm

```bash
# Download and install the Helm binary
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify installation
helm version
# version.BuildInfo{Version:"v3.x.x", ...}

# Enable bash completion (optional but useful in exam)
helm completion bash > /etc/bash_completion.d/helm
source /etc/bash_completion.d/helm

# View help
helm help
```

Helm v3 is the current version — Helm v2 (which required Tiller) is end-of-life. The CKA exam environment has Helm v3 pre-installed. Know the difference between `helm install` (v3) and the old `helm install <release> <chart>` syntax.

---

## Step 2 — Add Helm Repositories

```bash
# Add the official stable charts repository
helm repo add stable https://charts.helm.sh/stable

# Add Bitnami (widely used, includes nginx, mysql, postgres, etc.)
helm repo add bitnami https://charts.bitnami.com/bitnami

# Add ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Update all repos to fetch latest chart versions
helm repo update

# List configured repos
helm repo list

# Search for a chart
helm search repo nginx
helm search repo bitnami/nginx --versions | head -10
```

Helm repositories are like apt repositories for Kubernetes. `helm repo update` should be run before installing to get the latest chart versions. On the CKA exam, repos may be pre-configured.

---

## Step 3 — Inspect a Chart Before Installing

```bash
# View chart information and default values
helm show chart bitnami/nginx
helm show values bitnami/nginx | head -80

# Show all resources that would be created (dry run)
helm install my-nginx bitnami/nginx --dry-run --generate-name 2>&1 | head -50

# Alternatively, use helm template to render without connecting to cluster
helm template my-nginx bitnami/nginx | head -60
```

Always inspect `helm show values` before installing a chart. The `values.yaml` shows all configurable parameters. This is the equivalent of reading documentation and is allowed during the CKA exam.

---

## Step 4 — Install a Chart with Default Values

```bash
# Install nginx with default values
helm install my-nginx bitnami/nginx \
  --namespace web \
  --create-namespace

# Wait for the release to be deployed
helm status my-nginx -n web

# List installed releases
helm list -n web
helm list --all-namespaces

# View the resources created
kubectl get all -n web
```

`helm install <release-name> <chart>` deploys the chart with default values. The release name (`my-nginx`) is used to manage the lifecycle of all resources created by this chart.

---

## Step 5 — Override Values with --set

```bash
# Install with specific overrides using --set
helm install my-app bitnami/nginx \
  --namespace web \
  --set service.type=NodePort \
  --set service.nodePorts.http=30080 \
  --set replicaCount=2

# Verify the overrides took effect
kubectl get svc -n web my-app-nginx
# TYPE should be NodePort

# Multiple --set flags are combined
# Use --set for simple key-value overrides
# Use --set 'key={val1,val2}' for arrays
# Use --set 'key.subkey=val' for nested values
```

`--set` is for quick, one-off overrides. Use it for simple values. For complex configurations with many overrides, use a values file (Step 6).

---

## Step 6 — Override Values with -f values.yaml

```bash
# Create a custom values file
cat <<'EOF' > my-values.yaml
replicaCount: 3

service:
  type: ClusterIP
  port: 80

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 250m
    memory: 256Mi

podAnnotations:
  environment: "production"
  team: "platform"
EOF

# Install using the values file
helm install my-prod-nginx bitnami/nginx \
  --namespace production \
  --create-namespace \
  -f my-values.yaml

# You can combine -f and --set (--set takes precedence)
helm install my-nginx2 bitnami/nginx \
  -f my-values.yaml \
  --set replicaCount=5

# Check effective values used
helm get values my-prod-nginx -n production
```

`-f values.yaml` is preferred for production deployments where many values are customized. Values files are version-controlled and repeatable. During the CKA exam, you may need to create a values file and install a chart.

---

## Step 7 — Upgrade a Release

```bash
# Upgrade an existing release with new values
helm upgrade my-nginx bitnami/nginx \
  --namespace web \
  --set replicaCount=3

# Upgrade and install if not present (--install flag)
helm upgrade --install my-nginx bitnami/nginx \
  --namespace web \
  --set replicaCount=2

# Upgrade to a specific chart version
helm upgrade my-nginx bitnami/nginx \
  --namespace web \
  --version 18.1.0 \
  --set replicaCount=2

# View upgrade history
helm history my-nginx -n web
# REVISION  UPDATED   STATUS     CHART         APP VERSION  DESCRIPTION
# 1         ...       superseded nginx-18.x.x  1.x.x        Install complete
# 2         ...       deployed   nginx-18.x.x  1.x.x        Upgrade complete
```

`helm upgrade` applies new values and chart versions. The `--install` flag makes `upgrade` idempotent — it installs if the release doesn't exist. Every upgrade creates a new revision tracked in history.

---

## Step 8 — Roll Back a Release

```bash
# View release history to find the revision to roll back to
helm history my-nginx -n web

# Roll back to the previous revision
helm rollback my-nginx -n web

# Roll back to a specific revision number
helm rollback my-nginx 1 -n web

# Verify the rollback
helm history my-nginx -n web
# A new revision is created for the rollback (e.g., revision 3)

kubectl get pods -n web
kubectl rollout status deployment my-nginx-nginx -n web
```

`helm rollback` creates a new revision rather than reverting the revision counter. This means `helm history` always grows, providing a complete audit trail of changes.

---

## Step 9 — Use helm template to Render Manifests

```bash
# Render chart templates to YAML without installing
helm template my-nginx bitnami/nginx \
  --set replicaCount=2 \
  --set service.type=NodePort

# Render to a file and apply manually
helm template my-nginx bitnami/nginx \
  -f my-values.yaml \
  > rendered-nginx.yaml

kubectl apply -f rendered-nginx.yaml

# Useful for GitOps workflows where you commit rendered YAML
# Also useful to inspect exactly what a chart will create before installing

# Render with specific namespace
helm template my-nginx bitnami/nginx \
  --namespace web \
  --include-crds
```

`helm template` is extremely useful when you need to inspect what resources will be created, or when using GitOps tools (Flux, ArgoCD) that manage raw YAML rather than Helm releases.

---

## Step 10 — Inspect a Deployed Release

```bash
# Get all information about a release
helm get all my-nginx -n web

# Get just the computed values
helm get values my-nginx -n web

# Get just the rendered manifests
helm get manifest my-nginx -n web

# Get the notes (post-install instructions)
helm get notes my-nginx -n web

# Check if a release needs upgrade (compare deployed vs latest chart)
helm status my-nginx -n web
```

`helm get values` shows you the values that were actually used (not the defaults). This is invaluable for debugging unexpected behavior in a deployed release.

---

## Step 11 — Uninstall a Release

```bash
# Uninstall removes all resources created by the chart
helm uninstall my-nginx -n web

# Verify resources are gone
kubectl get all -n web

# By default, uninstall also removes the release history
# Use --keep-history to preserve history for audit purposes
helm uninstall my-prod-nginx -n production --keep-history

# Even after uninstall with --keep-history, you can still see history
helm history my-prod-nginx -n production
```

`helm uninstall` removes all Kubernetes resources created by the release. Without `--keep-history`, the release record is also deleted, making rollback impossible.

---

## Step 12 — Helm with Kubernetes Namespaces

```bash
# Helm releases are namespace-scoped
# The same release name can exist in different namespaces

helm install nginx bitnami/nginx -n dev --create-namespace
helm install nginx bitnami/nginx -n staging --create-namespace
helm install nginx bitnami/nginx -n production --create-namespace

# List releases across all namespaces
helm list -A
# Or
helm list --all-namespaces

# Work with a specific namespace
helm status nginx -n dev
helm upgrade nginx bitnami/nginx -n staging --set replicaCount=3
helm uninstall nginx -n dev
```

Each Helm release is identified by both its name and namespace. Always specify `-n <namespace>` when working with releases to avoid operating on the wrong environment.

---

## Free online tools
- **Helm documentation** (allowed in CKA exam): https://helm.sh/docs/
- **Artifact Hub** — find Helm charts: https://artifacthub.io
- **Kubernetes Docs**: https://kubernetes.io/docs/
- **killer.sh** — CKA mock exam: https://killer.sh

---

## What you learned
- Helm v3 manages Kubernetes application packages (charts) without a server-side component
- `helm repo add` + `helm repo update` configure and refresh chart repositories
- `helm show values <chart>` reveals all configurable parameters before installing
- `helm install <name> <chart>` deploys with defaults; `--set` and `-f` override values
- `-f values.yaml` is preferred for complex multi-value overrides; `--set` wins when both are used
- `helm upgrade` updates a running release; `--install` makes it idempotent
- `helm rollback <release> [revision]` reverts to a prior revision; a new revision is recorded
- `helm template` renders YAML locally without connecting to the cluster — useful for GitOps and auditing
- `helm get values` shows effective values used in a deployed release
- `helm list -A` shows releases across all namespaces; releases are namespace-scoped
- `helm uninstall` removes all chart-managed resources; use `--keep-history` for audit trails
