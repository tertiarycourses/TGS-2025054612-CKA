# Step 1 — CRI: talk to the runtime directly

`kubelet` talks to the runtime over a Unix socket. `crictl` is the debug client.

```bash
sudo crictl info | head -20
sudo crictl ps
sudo crictl images | head
```

Inspect the kubelet's runtime endpoint:

```bash
sudo cat /var/lib/kubelet/config.yaml | grep -E "runtime|cgroup"
ls /etc/crictl.yaml /run/containerd/containerd.sock 2>/dev/null
```
