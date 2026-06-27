# Lab 4 — Cluster Upgrade: v1.34 to v1.35 with kubeadm, Drain, kubelet, Uncordon

Upgrading a Kubernetes cluster is a mandatory CKA exam skill. This lab upgrades a two-node cluster from v1.34 to v1.35 following the official kubeadm upgrade procedure: unhold packages, upgrade kubeadm, run upgrade plan and apply on the control plane, drain the node, upgrade kubelet and kubectl, restart kubelet, then uncordon. The same procedure is then repeated on the worker node. Missing any step — especially the drain before kubelet upgrade — is a common exam mistake.

Run on https://killercoda.com/playgrounds/scenario/kubeadm

**Required software (free):**
- kubeadm (installed from Lab 1, currently at v1.34)
- kubelet (installed from Lab 1, currently at v1.34)
- kubectl (installed from Lab 1, currently at v1.34)

---

## Step 1 — Verify Current Cluster Version

```bash
# Check the current version before upgrading
kubectl version --short 2>/dev/null || kubectl version
# Server Version: v1.34.x

kubectl get nodes
# NAME           STATUS   ROLES           AGE   VERSION
# controlplane   Ready    control-plane   10m   v1.34.x
# worker01       Ready    <none>          8m    v1.34.x

# Check what version kubeadm can upgrade to
kubeadm version
# kubeadm version: v1.34.x
```

Always confirm the starting version before upgrading. Kubernetes only supports upgrading one minor version at a time (e.g., v1.34 → v1.35, not v1.33 → v1.35 directly).

---

## Step 2 — Add the v1.35 apt Repository on Control Plane

```bash
# Add the Kubernetes v1.35 package repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | \
  gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | \
  tee /etc/apt/sources.list.d/kubernetes.list

apt-get update

# Verify v1.35 packages are now available
apt-cache madison kubeadm | grep 1.35
```

Each minor version has its own apt repository. You must add the v1.35 repository before you can install v1.35 packages. On some exam environments this step is already done — always verify with `apt-cache madison`.

---

## Step 3 — Upgrade kubeadm on the Control Plane

```bash
# STEP 1 of upgrade sequence: unhold kubeadm
apt-mark unhold kubeadm

# Install the new kubeadm version
apt-get install -y kubeadm=1.35.0-*

# Re-hold kubeadm at the new version
apt-mark hold kubeadm

# Verify kubeadm upgraded
kubeadm version
# kubeadm version: v1.35.0

# Note: kubelet and kubectl are still at v1.34 at this point
kubelet --version
```

Only kubeadm is upgraded first. kubelet and kubectl are upgraded separately after `kubeadm upgrade apply` completes. This sequencing is critical — upgrading kubelet before kubeadm apply will break the upgrade.

---

## Step 4 — Run kubeadm upgrade plan

```bash
# Review what will be upgraded
kubeadm upgrade plan

# Expected output shows:
# COMPONENT                 CURRENT    TARGET
# kube-apiserver            v1.34.x    v1.35.0
# kube-controller-manager   v1.34.x    v1.35.0
# kube-scheduler            v1.34.x    v1.35.0
# kube-proxy                v1.34.x    v1.35.0
# CoreDNS                   x.x.x      x.x.x
# etcd                      x.x.x      x.x.x (local)

# Check for any preflight warnings
kubeadm upgrade plan v1.35.0
```

`kubeadm upgrade plan` performs pre-flight checks and shows what version each component will be upgraded to. Review this output carefully before proceeding to `upgrade apply`.

---

## Step 5 — Apply the Upgrade on the Control Plane

```bash
# This upgrades the control plane static pod manifests and cluster configs
# It will briefly interrupt the API server (usually < 30 seconds)
kubeadm upgrade apply v1.35.0

# Watch the upgrade progress — it will:
# 1. Run preflight checks
# 2. Pull new images
# 3. Update static pod manifests in /etc/kubernetes/manifests/
# 4. Update kubeadm ConfigMap
# 5. Update RBAC
# 6. Print: [upgrade/successful] SUCCESS! Your cluster was upgraded to v1.35.0.

# Verify new manifests
grep 'image:' /etc/kubernetes/manifests/kube-apiserver.yaml
# registry.k8s.io/kube-apiserver:v1.35.0
```

`kubeadm upgrade apply` updates the static pod manifests and kubelet restarts each control plane pod. The API server will be briefly unavailable during its restart. kubectl commands will fail temporarily.

---

## Step 6 — Drain the Control Plane Node

```bash
# Before upgrading kubelet, drain the node to safely evict workloads
kubectl drain controlplane \
  --ignore-daemonsets \
  --delete-emptydir-data

# Verify the node is cordoned (SchedulingDisabled)
kubectl get nodes
# NAME           STATUS                     ROLES           VERSION
# controlplane   Ready,SchedulingDisabled   control-plane   v1.34.x

# Check that pods were evicted (DaemonSet pods remain)
kubectl get pods -o wide | grep controlplane
```

Draining evicts all evictable pods from the node and marks it as `SchedulingDisabled` (cordoned). `--ignore-daemonsets` skips DaemonSet pods (they cannot be evicted). `--delete-emptydir-data` removes pods using emptyDir volumes.

---

## Step 7 — Upgrade kubelet and kubectl on the Control Plane

```bash
# Unhold both packages
apt-mark unhold kubelet kubectl

# Install the new versions
apt-get install -y kubelet=1.35.0-* kubectl=1.35.0-*

# Re-hold at new version
apt-mark hold kubelet kubectl

# Reload systemd and restart kubelet
systemctl daemon-reload
systemctl restart kubelet

# Verify kubelet upgraded
kubelet --version
# Kubernetes v1.35.0

# Check kubelet is running
systemctl status kubelet --no-pager
```

`systemctl daemon-reload` is required after a binary update to reload the service unit file. Forgetting this step is a common exam mistake that causes `systemctl restart kubelet` to start the old version.

---

## Step 8 — Uncordon the Control Plane Node

```bash
# Mark the control plane node as schedulable again
kubectl uncordon controlplane

# Verify the node is Ready and schedulable
kubectl get nodes
# NAME           STATUS   ROLES           AGE   VERSION
# controlplane   Ready    control-plane   15m   v1.35.0

# The VERSION field now shows v1.35.0 for the control plane
```

The node returns to `Ready` status after uncordon. The VERSION field in `kubectl get nodes` reflects the kubelet version, not the API server version. After this step, the control plane upgrade is complete.

---

## Step 9 — Upgrade kubeadm on the Worker Node

```bash
# SSH to the worker node (or run in a second terminal)
# ssh worker01

# Add the v1.35 repository on the worker node
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | \
  gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | \
  tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-mark unhold kubeadm
apt-get install -y kubeadm=1.35.0-*
apt-mark hold kubeadm

# On the worker node, run upgrade node (not upgrade apply)
kubeadm upgrade node
# This upgrades the local kubelet configuration on the worker
```

`kubeadm upgrade node` is used on worker nodes (not `kubeadm upgrade apply`). It downloads the new kubelet configuration from the ConfigMap created during the control plane upgrade.

---

## Step 10 — Drain the Worker Node (from Control Plane)

```bash
# Run from the CONTROL PLANE
kubectl drain worker01 \
  --ignore-daemonsets \
  --delete-emptydir-data

# Verify worker is cordoned
kubectl get nodes
# NAME           STATUS                     ROLES
# controlplane   Ready                      control-plane
# worker01       Ready,SchedulingDisabled   <none>

# Workloads should now be running on the control plane (temporarily)
kubectl get pods -o wide
```

Always drain the worker from the control plane, not from the worker itself. This ensures the Kubernetes scheduler properly evicts pods and respects PodDisruptionBudgets.

---

## Step 11 — Upgrade kubelet and kubectl on the Worker Node

```bash
# Run ON THE WORKER NODE

apt-mark unhold kubelet kubectl
apt-get install -y kubelet=1.35.0-* kubectl=1.35.0-*
apt-mark hold kubelet kubectl

systemctl daemon-reload
systemctl restart kubelet

# Verify from the CONTROL PLANE
kubectl get nodes
# NAME           STATUS                     ROLES           VERSION
# controlplane   Ready                      control-plane   v1.35.0
# worker01       Ready,SchedulingDisabled   <none>          v1.35.0
```

After the kubelet restart on the worker, its version shows as v1.35.0 in `kubectl get nodes`. The node is still cordoned until the next step.

---

## Step 12 — Uncordon the Worker Node and Verify

```bash
# Run from the CONTROL PLANE
kubectl uncordon worker01

# Final verification — both nodes should be Ready at v1.35.0
kubectl get nodes
# NAME           STATUS   ROLES           AGE   VERSION
# controlplane   Ready    control-plane   20m   v1.35.0
# worker01       Ready    <none>          18m   v1.35.0

# Verify all system pods are healthy
kubectl get pods -n kube-system
kubectl get pods -n calico-system

# Confirm API server version
kubectl version
# Server Version: v1.35.0
```

The upgrade is complete. The full procedure takes approximately 10-15 minutes for a two-node cluster. On the CKA exam, practice this procedure until you can do it in under 15 minutes from memory.

---

## Step 13 — Upgrade Summary Cheat Sheet

```
CONTROL PLANE UPGRADE ORDER:
1. apt-mark unhold kubeadm
2. apt-get install -y kubeadm=1.35.0-*
3. apt-mark hold kubeadm
4. kubeadm upgrade plan
5. kubeadm upgrade apply v1.35.0
6. kubectl drain <control-plane> --ignore-daemonsets --delete-emptydir-data
7. apt-mark unhold kubelet kubectl
8. apt-get install -y kubelet=1.35.0-* kubectl=1.35.0-*
9. apt-mark hold kubelet kubectl
10. systemctl daemon-reload && systemctl restart kubelet
11. kubectl uncordon <control-plane>

WORKER NODE UPGRADE ORDER (repeat for each worker):
1. apt-mark unhold kubeadm (on worker)
2. apt-get install -y kubeadm=1.35.0-* (on worker)
3. kubeadm upgrade node (on worker)
4. kubectl drain <worker> ... (from control plane)
5. apt-mark unhold kubelet kubectl (on worker)
6. apt-get install -y kubelet=1.35.0-* kubectl=1.35.0-* (on worker)
7. systemctl daemon-reload && systemctl restart kubelet (on worker)
8. kubectl uncordon <worker> (from control plane)
```

---

## Free online tools
- **Kubernetes Docs — cluster upgrade**: https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/
- **killer.sh** — CKA mock exam (upgrade questions are common): https://killer.sh
- **Killercoda kubeadm playground**: https://killercoda.com/playgrounds/scenario/kubeadm

---

## What you learned
- Kubernetes upgrades are one minor version at a time only (v1.34 → v1.35, not v1.33 → v1.35)
- The upgrade sequence: unhold → apt install kubeadm → upgrade plan → upgrade apply → drain → kubelet upgrade → uncordon
- `kubeadm upgrade apply` is for the control plane; `kubeadm upgrade node` is for workers
- `apt-mark unhold` must precede any package upgrade; `apt-mark hold` should follow
- `systemctl daemon-reload` is required after binary update before restarting kubelet
- `kubectl drain --ignore-daemonsets --delete-emptydir-data` is the correct drain command for node maintenance
- `kubectl uncordon` re-enables scheduling after maintenance is complete
- The VERSION column in `kubectl get nodes` shows kubelet version, not API server version
- Workers are drained from the control plane, not from the worker node itself
