# Lab 4 — Cluster Upgrade with kubeadm

In this lab you upgrade a Kubernetes cluster from v1.30 to v1.31 using `kubeadm`. You will follow the recommended order: control plane first, then workers, draining each node before the kubelet restart.

Use the **kubeadm playground** with a pre-installed v1.30 cluster. If you only have v1.31 available, demonstrate the patch-upgrade path (e.g. v1.31.0 → v1.31.1) — the commands are identical.

**What you will do:**
- Check current cluster and component versions
- Upgrade the kubeadm binary on the control plane
- Plan and apply the control-plane upgrade with `kubeadm upgrade apply`
- Drain the control plane and upgrade its kubelet and kubectl
- Repeat the drain-upgrade-uncordon cycle on the worker node
