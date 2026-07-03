# Step 2 — Upgrade the kubeadm binary on the control plane

```bash
sudo apt-mark unhold kubeadm
sudo apt update
sudo apt install -y kubeadm=1.31.0-1.1
sudo apt-mark hold kubeadm
kubeadm version
```
