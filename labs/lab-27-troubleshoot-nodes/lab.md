# Lab 27 — Troubleshoot Nodes

Nodes go `NotReady` when the kubelet can't report healthy. In this lab you simulate three common node-level failures and recover from each.

**Lab environment:** [KillerCoda](https://killercoda.com/tertiary-labs-cka/course/killercoda/lab-27-troubleshoot-nodes)
---

## Step 1 — Baseline

```bash
kubectl get nodes
kubectl describe node node01 | grep -E "Conditions|Taints" -A6
```

The five conditions: `Ready`, `MemoryPressure`, `DiskPressure`, `PIDPressure`, `NetworkUnavailable`.

---

## Step 2 — Stop the kubelet

On **node01**:

```bash
sudo systemctl stop kubelet
```

Back on **controlplane** (wait ~40 s):

```bash
kubectl get nodes
# node01   NotReady
```

`kubectl describe node node01` shows `Kubelet stopped posting node status`.

Fix:

```bash
# on node01
sudo systemctl start kubelet
sudo journalctl -u kubelet -n 20 --no-pager
```

---

## Step 3 — Break the kubelet config

On **node01**:

```bash
sudo cp /var/lib/kubelet/config.yaml /var/lib/kubelet/config.yaml.bak
sudo sed -i 's/cgroupDriver: systemd/cgroupDriver: cgroupfs/' /var/lib/kubelet/config.yaml
sudo systemctl restart kubelet
sudo journalctl -u kubelet -n 30 --no-pager | grep -i cgroup
```

`misconfiguration: kubelet cgroup driver: "cgroupfs" is different from docker cgroup driver: "systemd"` — and the node won't reach `Ready`.

Recover:

```bash
sudo cp /var/lib/kubelet/config.yaml.bak /var/lib/kubelet/config.yaml
sudo systemctl restart kubelet
```

---

## Step 4 — Cordon and drain

Sometimes you need to take a node out of service safely.

```bash
kubectl cordon node01
kubectl get nodes
kubectl drain node01 --ignore-daemonsets --delete-emptydir-data
```

`cordon` marks unschedulable; `drain` evicts existing pods.

Bring it back:

```bash
kubectl uncordon node01
```

---

## Step 5 — Disk pressure simulation

```bash
# on node01 — fill /var to >85% (DO NOT do this on a real cluster)
sudo fallocate -l 5G /var/big.fill
```

After ~1 minute:

```bash
kubectl describe node node01 | grep -A2 DiskPressure
kubectl get events --field-selector reason=NodeHasDiskPressure -A
```

Pods may be evicted. Recover:

```bash
sudo rm /var/big.fill
```

---

## Step 6 — Container runtime down

```bash
# on node01
sudo systemctl stop containerd
kubectl get nodes
sudo journalctl -u kubelet -n 10 --no-pager
sudo systemctl start containerd
```

The kubelet's CRI connection fails — node flips to `NotReady` until containerd is back.

---

## Step 7 — Triage checklist

When a node is `NotReady`:
1. `kubectl describe node <name>` — check Conditions.
2. SSH in. `systemctl status kubelet containerd`.
3. `journalctl -u kubelet -u containerd -n 50 --no-pager`.
4. `sudo crictl ps` — runtime sanity check.
5. Disk: `df -h`. Memory: `free -h`. PIDs: `cat /proc/sys/kernel/pid_max` vs `ps -e | wc -l`.
6. Network: `kubectl get pods -A -o wide` — are CNI pods on this node `Running`?

---

## What you learned
- kubelet + containerd are the node's lifeline.
- Five node conditions and the symptoms that trigger each.
- Cordon, drain, uncordon for planned maintenance.
