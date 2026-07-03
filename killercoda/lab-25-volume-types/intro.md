# Lab 25 — Volume Types in Pods

Beyond PVCs, pods can mount many in-tree volume types: `emptyDir`, `hostPath`, `configMap`, `secret`, `projected`, `downwardAPI`. In this lab you exercise each of them.

**What you will do:**
- Use `emptyDir` to share scratch space between containers in the same pod
- Mount a node directory with `hostPath`
- Mount ConfigMap and Secret data as files inside a container
- Combine multiple sources into one mount point using `projected`
- Expose pod metadata (labels, name) to the container via `downwardAPI`
- Clean up all pods and resources created during the lab
