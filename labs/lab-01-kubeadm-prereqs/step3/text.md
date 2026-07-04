# Step 3 — Disable swap

`kubelet` refuses to start if swap is on.

```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

Verify swap is off:
```bash
free -h | grep Swap
```

`Swap: 0B 0B 0B` confirms swap is disabled.
