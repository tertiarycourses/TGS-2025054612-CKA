# Lab 27 — Troubleshoot Nodes

A node transitions to `NotReady` when the kubelet stops reporting. CKA 2026 tests diagnosing three common causes: kubelet service failure, cgroup driver mismatch, and containerd failure. You must also know how to safely drain a node for maintenance.

Run on https://killercoda.com/playgrounds/scenario/kubeadm

**Required software (free):**
- `kubectl` (pre-installed on Killercoda)
- `systemctl`, `journalctl` (pre-installed)

---

## Step 1 — Check node status baseline

```bash
kubectl get nodes -o wide
kubectl describe node node01 | grep -A10 Conditions
```

Both nodes should be `Ready`. Note the Conditions section — you will compare after breaking things.

---

## Step 2 — Scenario 1: kubelet service stops

On **node01** terminal:

```bash
sudo systemctl stop kubelet
```

On **controlplane** — watch the node go `NotReady`:

```bash
kubectl get nodes -w
```

After ~40 seconds node01 shows `NotReady`. Press Ctrl+C.

Diagnose on **node01**:

```bash
sudo systemctl status kubelet --no-pager
sudo journalctl -u kubelet --since "2 minutes ago" | tail -20
```

Fix:

```bash
sudo systemctl start kubelet
kubectl get nodes
```

---

## Step 3 — Scenario 2: cgroup driver mismatch

On **node01**:

```bash
sudo cp /var/lib/kubelet/config.yaml /tmp/kubelet-config-backup.yaml
sudo sed -i 's/cgroupDriver: systemd/cgroupDriver: cgroupfs/' /var/lib/kubelet/config.yaml
sudo systemctl restart kubelet
```

On **controlplane**:

```bash
kubectl get nodes -w
kubectl describe node node01 | grep -A5 Conditions
```

node01 goes `NotReady`. On **node01**:

```bash
sudo journalctl -u kubelet --since "1 minute ago" | grep -i "cgroup\|error" | tail -10
```

Fix:

```bash
sudo cp /tmp/kubelet-config-backup.yaml /var/lib/kubelet/config.yaml
sudo systemctl restart kubelet
kubectl get nodes
```

---

## Step 4 — Scenario 3: containerd stops

On **node01**:

```bash
sudo systemctl stop containerd
```

On **controlplane**:

```bash
kubectl get nodes -w
```

node01 goes `NotReady` immediately — kubelet loses its CRI connection.

Diagnose on **node01**:

```bash
sudo systemctl status containerd --no-pager
sudo journalctl -u kubelet --since "1 minute ago" | grep -i "CRI\|runtime\|connect" | tail -10
```

Fix:

```bash
sudo systemctl start containerd
kubectl get nodes
```

---

## Step 5 — Cordon and drain for planned maintenance

```bash
kubectl cordon node01
kubectl get nodes
```

`SchedulingDisabled` — no new Pods will be placed on node01.

```bash
kubectl drain node01 --ignore-daemonsets --delete-emptydir-data
kubectl get pods -o wide
```

All non-DaemonSet Pods are evicted. After maintenance:

```bash
kubectl uncordon node01
kubectl get nodes
```

---

## Step 6 — Node troubleshooting checklist

```bash
# 1. Node status and conditions
kubectl describe node <name> | grep -A10 Conditions

# 2. kubelet service
sudo systemctl status kubelet
sudo journalctl -u kubelet -n 50

# 3. containerd service
sudo systemctl status containerd
sudo journalctl -u containerd -n 20

# 4. Disk / memory pressure
kubectl describe node <name> | grep -E "pressure|capacity|allocatable"

# 5. CNI pods on node
kubectl get pods -n kube-system -o wide | grep <node-name>
```

---

## Free online tools

- **Node troubleshooting docs**: https://kubernetes.io/docs/tasks/debug/debug-cluster/
- **kubelet config reference**: https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/
- **killer.sh** — CKA mock exam: https://killer.sh
- **Kubernetes docs** (allowed in CKA exam): https://kubernetes.io/docs/

---

## What you learned

- `NotReady` within 40s usually means kubelet stopped — check `systemctl status kubelet`.
- cgroup driver mismatch (`systemd` vs `cgroupfs`) breaks kubelet — check `/var/lib/kubelet/config.yaml`.
- containerd failure cuts the kubelet CRI connection — `systemctl status containerd`.
- `kubectl cordon` → `kubectl drain --ignore-daemonsets` → maintenance → `kubectl uncordon` is the safe node maintenance sequence.
