# Step 5 — Read the CRI socket type from the kubelet config

```bash
sudo grep -E "containerRuntimeEndpoint|imageServiceEndpoint" /var/lib/kubelet/config.yaml
```

On modern clusters the value is `unix:///run/containerd/containerd.sock`.
