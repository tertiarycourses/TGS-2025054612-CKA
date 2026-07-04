# Step 3 — Diagnose

The API is gone, so use container-level tools.

```bash
sudo crictl ps -a | grep apiserver
sudo crictl logs $(sudo crictl ps -a | grep apiserver | awk '{print $1}' | head -1) 2>&1 | tail -20
sudo journalctl -u kubelet --no-pager | tail -30
```
