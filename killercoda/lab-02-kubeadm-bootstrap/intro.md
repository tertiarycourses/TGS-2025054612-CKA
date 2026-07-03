# Lab 2 — Bootstrap a Cluster with kubeadm

In this lab you will turn the two prepared nodes from Lab 1 into a working Kubernetes cluster. You will run `kubeadm init` on the control plane, copy the admin kubeconfig, then join the worker with the bootstrap token.

Continue on the **kubeadm playground**: https://killercoda.com/playgrounds/scenario/kubeadm

**What you will do:**
- Run `kubeadm init` on the control plane to bootstrap the cluster
- Configure `kubectl` by copying the admin kubeconfig
- Join the worker node using the bootstrap token from `kubeadm init`
- Inspect the running cluster components
- Explore the files kubeadm created on disk
