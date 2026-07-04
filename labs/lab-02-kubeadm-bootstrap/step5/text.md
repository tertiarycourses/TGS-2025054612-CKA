# Step 5 — Explore what kubeadm built

```bash
ls /etc/kubernetes/
ls /etc/kubernetes/manifests/
ls /etc/kubernetes/pki/
```

- `manifests/*.yaml` — static pod definitions watched by kubelet.
- `pki/` — the CA, API server, etcd, and service-account keys.
- `admin.conf`, `controller-manager.conf`, `scheduler.conf`, `kubelet.conf` — kubeconfigs for each component.
