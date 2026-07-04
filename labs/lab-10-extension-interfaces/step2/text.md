# Step 2 — CNI: where the network plugin lives

```bash
ls /etc/cni/net.d/
ls /opt/cni/bin/
```

`/etc/cni/net.d/*.conflist` is the active CNI config. `/opt/cni/bin/` holds the plugin binaries. The kubelet calls these binaries every time a pod is created or deleted.

Look at the live CNI config:

```bash
cat /etc/cni/net.d/*.conflist | head -40
```
