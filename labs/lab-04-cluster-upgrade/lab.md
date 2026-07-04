# Lab 4 — Cluster Upgrade with kubeadm

In this lab you upgrade a Kubernetes cluster from v1.30 to v1.31 using `kubeadm`. You will follow the recommended order: control plane first, then workers, draining each node before the kubelet restart.

**Lab environment:** [Play with Kubernetes](https://killercoda.com/playgrounds/course/kubernetes-playgrounds)

Use a kubeadm cluster with a pre-installed v1.30 cluster. If you only have v1.31 available, demonstrate the patch-upgrade path (e.g. v1.31.0 → v1.31.1) — the commands are identical.

---

## Step 1 — Check current versions

```bash
kubectl get nodes
kubeadm version
kubelet --version
```

---

## Step 2 — Upgrade the kubeadm binary on the control plane

```bash
sudo apt-mark unhold kubeadm
sudo apt update
sudo apt install -y kubeadm=1.31.0-1.1
sudo apt-mark hold kubeadm
kubeadm version
```

---

## Step 3 — Plan and apply on the control plane

```bash
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.31.0 -y
```

`upgrade apply` upgrades the static pods in `/etc/kubernetes/manifests/` one at a time, with health checks between each.

---

## Step 4 — Drain the control plane

```bash
kubectl drain controlplane --ignore-daemonsets
```

Drain evicts regular pods so the kubelet restart doesn't disrupt running workloads.

---

## Step 5 — Upgrade kubelet and kubectl on the control plane

```bash
sudo apt-mark unhold kubelet kubectl
sudo apt install -y kubelet=1.31.0-1.1 kubectl=1.31.0-1.1
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload
sudo systemctl restart kubelet
kubectl uncordon controlplane
```

---

## Step 6 — Repeat on the worker

On **node01**:

```bash
sudo apt-mark unhold kubeadm && sudo apt install -y kubeadm=1.31.0-1.1 && sudo apt-mark hold kubeadm
sudo kubeadm upgrade node
```

Back on **controlplane**:

```bash
kubectl drain node01 --ignore-daemonsets --delete-emptydir-data
```

On **node01**:

```bash
sudo apt-mark unhold kubelet kubectl
sudo apt install -y kubelet=1.31.0-1.1 kubectl=1.31.0-1.1
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload && sudo systemctl restart kubelet
```

On **controlplane**:

```bash
kubectl uncordon node01
kubectl get nodes
```

Both nodes should report the new version.

---

## What you learned
- The official kubeadm upgrade order: kubeadm → upgrade apply → drain → kubelet → uncordon.
- Why `apt-mark hold` is unset and re-set around each step.
- How `kubeadm upgrade node` differs from `kubeadm upgrade apply`.
