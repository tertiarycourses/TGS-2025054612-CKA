# Lab 4 — Cluster Upgrade with kubeadm

In this lab you upgrade a Kubernetes cluster from v1.34 to v1.35 using `kubeadm`. You will follow the recommended order: control plane first, then workers, draining each node before the kubelet restart.

A **v1.34 cluster is being provisioned in the background** — it will be ready by the time you finish reading this intro. Wait for the prompt to return before running Step 1 commands.

**What you will do:**
- Check current cluster and component versions
- Upgrade the kubeadm binary on the control plane
- Plan and apply the control-plane upgrade with `kubeadm upgrade apply`
- Drain the control plane and upgrade its kubelet and kubectl
- Repeat the drain-upgrade-uncordon cycle on the worker node
