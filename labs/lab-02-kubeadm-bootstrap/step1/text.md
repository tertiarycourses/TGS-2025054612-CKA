# Step 1 — Initialize the control plane

On the **controlplane** node:

```bash
sudo kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --apiserver-advertise-address=$(hostname -I | awk '{print $1}')
```

- `--pod-network-cidr` reserves a non-overlapping range for the CNI plugin (Calico's default).
- `--apiserver-advertise-address` pins the API server to the node's primary IP so workers can reach it.

`kubeadm init` runs preflight checks, generates PKI in `/etc/kubernetes/pki`, writes static-pod manifests in `/etc/kubernetes/manifests`, and prints a `kubeadm join` command at the end. **Copy that join command** — you'll need it in Step 3.
