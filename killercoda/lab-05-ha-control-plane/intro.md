# Lab 5 — Highly-Available Control Plane

In this lab you study the architecture of a Highly-Available (HA) Kubernetes control plane and reproduce the key configuration pieces. You will not stand up three real control-plane VMs (the free Killercoda playground gives you two nodes), but you will configure the load-balancer front end and run a `kubeadm init` with the `--control-plane-endpoint` flag that an HA cluster requires.

Use the **kubeadm playground**: https://killercoda.com/playgrounds/scenario/kubeadm

**What you will do:**
- Understand the stacked-etcd HA topology and the role of a virtual IP
- Install and configure HAProxy and keepalived for the VIP
- Run `kubeadm init` with `--control-plane-endpoint` and `--upload-certs`
- Review the join command for additional control planes
- Verify etcd quorum with `etcdctl member list`
