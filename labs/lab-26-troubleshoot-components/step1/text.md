# Step 1 — Map components to their on-disk source

```bash
sudo ls /etc/kubernetes/manifests/
```

Each YAML is a **static pod** the kubelet watches and runs:
- `kube-apiserver.yaml`
- `kube-controller-manager.yaml`
- `kube-scheduler.yaml`
- `etcd.yaml`

```bash
sudo systemctl status kubelet --no-pager | head
sudo systemctl status containerd --no-pager | head
```

`kubelet` and `containerd` run as systemd services, not pods.
