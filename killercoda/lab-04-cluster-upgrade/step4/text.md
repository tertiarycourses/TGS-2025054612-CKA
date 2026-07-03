# Step 4 — Drain the control plane

```bash
kubectl drain controlplane --ignore-daemonsets
```

Drain evicts regular pods so the kubelet restart doesn't disrupt running workloads.
