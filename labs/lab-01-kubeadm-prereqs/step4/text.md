# Step 4 — Install containerd

```bash
sudo apt update
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
```

`SystemdCgroup = true` aligns containerd's cgroup driver with the kubelet default — mismatched drivers are the #1 cause of "node NotReady" in fresh clusters.

Verify:
```bash
sudo systemctl status containerd --no-pager | head -5
```

You should see `active (running)`.
