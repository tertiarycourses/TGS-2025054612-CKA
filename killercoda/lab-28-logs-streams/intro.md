# Lab 28 — Application Logs and Container Streams

Containers emit logs to `stdout` and `stderr`. The kubelet redirects these to `/var/log/pods/...`, and `kubectl logs` reads them back. In this lab you inspect single-container, multi-container, and previous-instance logs, then look at the files on disk.

**What you will do:**
- Stream and tail logs from a single-container deployment
- Retrieve logs from a previous (crashed) container instance with `--previous`
- Select specific containers in a multi-container pod with `-c` and `--all-containers`
- Read the raw JSON log files on the host under `/var/log/pods/`
- Install `stern` for multi-pod log tailing across namespaces
- Clean up all deployments and pods
