# Step 1 — Load kernel modules

The Kubernetes networking stack needs the `br_netfilter` and `overlay` kernel modules.

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
```

`overlay` powers the containerd snapshotter; `br_netfilter` lets iptables see bridged traffic so kube-proxy can NAT it.

Verify the modules are loaded:
```bash
lsmod | grep -E 'overlay|br_netfilter'
```

You should see both modules listed.
