# Lab 3 — Install a CNI Plugin (Calico)

A fresh kubeadm cluster has no pod network. In this lab you install Calico, watch the nodes flip from `NotReady` to `Ready`, and verify pod-to-pod connectivity across nodes.

Continue on the **kubeadm playground** from Lab 2.

**What you will do:**
- Apply the Calico manifest to install the CNI plugin
- Watch the Calico DaemonSet and kube-system pods come up
- Run test pods on different nodes and confirm cross-node ping works
- Inspect the CNI configuration files and binaries on a node
- Clean up the test pods
