# Step 6 — Container runtime down

```bash
# on node01
sudo systemctl stop containerd
kubectl get nodes
sudo journalctl -u kubelet -n 10 --no-pager
sudo systemctl start containerd
```

The kubelet's CRI connection fails — node flips to `NotReady` until containerd is back.
