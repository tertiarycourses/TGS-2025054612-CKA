# Step 4 — Inspect the CNI configuration

On a worker:

```bash
ls /etc/cni/net.d/
cat /etc/cni/net.d/10-calico.conflist
ls /opt/cni/bin/ | grep calico
```

`/etc/cni/net.d/` is what kubelet reads to decide which plugin to invoke for every new pod.
