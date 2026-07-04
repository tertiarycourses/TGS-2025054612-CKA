# Step 5 — Upgrade kubelet and kubectl on the control plane

```bash
sudo apt-mark unhold kubelet kubectl
sudo apt install -y kubelet=1.31.0-1.1 kubectl=1.31.0-1.1
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload
sudo systemctl restart kubelet
kubectl uncordon controlplane
```
