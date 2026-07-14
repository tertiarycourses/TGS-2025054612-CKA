# Step 3 — Plan and apply on the control plane

```bash
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.35.0 -y
```

`upgrade apply` upgrades the static pods in `/etc/kubernetes/manifests/` one at a time, with health checks between each.
