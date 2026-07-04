# Lab 6 — Install Components with Helm

Helm is the package manager for Kubernetes. In this lab you install Helm, add a chart repository, deploy nginx via the Bitnami chart, override values, and roll back.

**Lab environment:** [KillerCoda](https://killercoda.com/tertiary-labs-cka/course/labs/lab-06-helm)
---

## Step 1 — Install the Helm CLI

```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

---

## Step 2 — Add a chart repository

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm search repo bitnami/nginx
```

`helm repo update` refreshes the local index. `helm search` queries it.

---

## Step 3 — Install a chart

```bash
helm install web bitnami/nginx \
  --namespace web --create-namespace \
  --set service.type=ClusterIP \
  --set replicaCount=2
```

`web` is the **release name** — your installation's identity in the cluster.

```bash
kubectl -n web get all
helm -n web list
```

---

## Step 4 — Override values with a file

Create `values.yaml`:

```yaml
replicaCount: 3
image:
  tag: 1.27
service:
  type: ClusterIP
```

Apply it:

```bash
helm upgrade web bitnami/nginx -n web -f values.yaml
kubectl -n web get deploy
helm -n web history web
```

---

## Step 5 — Roll back

```bash
helm -n web rollback web 1
helm -n web history web
```

Helm keeps the manifests of every revision in cluster secrets so rollback is instant.

---

## Step 6 — Render without installing

```bash
helm template web bitnami/nginx -f values.yaml | head -50
```

`helm template` is the GitOps-friendly alternative — it just renders YAML, no Tiller-style state in-cluster.

---

## Step 7 — Uninstall

```bash
helm -n web uninstall web
kubectl delete ns web
```

---

## What you learned
- The release / chart / repo model.
- How `--set` and `-f values.yaml` override defaults.
- Rollback, history, and `helm template` for GitOps.
