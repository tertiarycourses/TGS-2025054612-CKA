# Lab 7 — Customize Manifests with Kustomize

Kustomize is the template-free overlay tool baked into `kubectl` (`kubectl apply -k`). In this lab you build a base nginx Deployment and two overlays (`dev`, `prod`) that change the replica count, image tag, and namespace without copying YAML.

Use the **Kubernetes playground**: https://killercoda.com/playgrounds/scenario/kubernetes

**What you will do:**
- Create a base Deployment and Service with a `kustomization.yaml`
- Create a `dev` overlay with a JSON6902 patch for replicas and image tag
- Create a `prod` overlay with different replicas and image tag
- Render with `kubectl kustomize` and apply both overlays to the cluster
- Replace the JSON6902 patch with a strategic-merge patch
