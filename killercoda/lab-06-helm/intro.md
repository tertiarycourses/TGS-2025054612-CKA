# Lab 6 — Install Components with Helm

Helm is the package manager for Kubernetes. In this lab you install Helm, add a chart repository, deploy nginx via the Bitnami chart, override values, and roll back.

Use the **Kubernetes playground**: https://killercoda.com/playgrounds/scenario/kubernetes

**What you will do:**
- Install the Helm CLI
- Add the Bitnami chart repository and search for charts
- Deploy nginx with `helm install`, overriding values via `--set`
- Upgrade the release using a `values.yaml` file
- Roll back to a previous revision with `helm rollback`
- Render manifests with `helm template` (no cluster state)
- Uninstall the release and clean up
