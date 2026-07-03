# Lab 26 — Troubleshoot Cluster Components

When the control plane misbehaves, you need to know which static pod, systemd service, or socket to inspect. In this lab you break the API server's static-pod manifest, observe the symptoms, and recover.

**What you will do:**
- Map each control-plane component to its on-disk manifest or systemd service
- Intentionally break the API server by changing its bind port
- Diagnose the failure using `crictl` and `journalctl` when `kubectl` is unavailable
- Restore the API server and verify cluster recovery
- Check etcd health using `etcdctl`
- Inspect kube-controller-manager and kube-scheduler logs
- Reference a cheat sheet mapping symptoms to the correct diagnostic tools
