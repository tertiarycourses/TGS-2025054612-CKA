# Lab 1 — kubeadm Prerequisites and Container Runtime

Prepare this Ubuntu node for a Kubernetes cluster install.

**What you will do:**
- Load the kernel modules required by Kubernetes networking
- Apply the required sysctls
- Disable swap
- Install containerd as the Container Runtime Interface (CRI)
- Install kubeadm, kubelet, and kubectl from the official Kubernetes apt repository

**Goal:** By the end of this lab the node is fully prepped and ready for `kubeadm init` in Lab 2.
