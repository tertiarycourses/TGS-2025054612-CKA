# Lab 10 — Extension Interfaces (CNI, CSI, CRI)

Kubernetes plugs into the host via three standard interfaces:
- **CRI** — Container Runtime Interface (containerd, CRI-O)
- **CNI** — Container Network Interface (Calico, Cilium, Flannel)
- **CSI** — Container Storage Interface (AWS EBS, GCE PD, local-path, Ceph)

In this lab you inspect each one on a running cluster.

**What you will do:**
- Use `crictl` to talk to the container runtime directly
- Inspect CNI configuration files and plugin binaries on disk
- List CSI drivers, CSI nodes, and storage classes
- Trace a pod through all three interfaces (CRI, CNI, CSI)
- Read the CRI socket endpoint from the kubelet config
