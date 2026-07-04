# Step 3 — Break the kubelet config

On **node01**:

```bash
sudo cp /var/lib/kubelet/config.yaml /var/lib/kubelet/config.yaml.bak
sudo sed -i 's/cgroupDriver: systemd/cgroupDriver: cgroupfs/' /var/lib/kubelet/config.yaml
sudo systemctl restart kubelet
sudo journalctl -u kubelet -n 30 --no-pager | grep -i cgroup
```

`misconfiguration: kubelet cgroup driver: "cgroupfs" is different from docker cgroup driver: "systemd"` — and the node won't reach `Ready`.

Recover:

```bash
sudo cp /var/lib/kubelet/config.yaml.bak /var/lib/kubelet/config.yaml
sudo systemctl restart kubelet
```
