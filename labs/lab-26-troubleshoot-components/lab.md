# Lab 26 — Troubleshoot Cluster Components

When the control plane misbehaves, you need to know which static pod, systemd service, or socket to inspect. In this lab you break the API server's static-pod manifest, observe the symptoms, and recover.

**Lab environment:** [KillerCoda](https://killercoda.com/tertiary-labs-cka/course/killercoda/lab-26-troubleshoot-components)

https://killercoda.com/tertiary-labs-cka/course/killercoda/lab-26-troubleshoot-components — complete Labs 1–3 first, then continue here.

---

## Step 1 — Map components to their on-disk source

```bash
sudo ls /etc/kubernetes/manifests/
```

Each YAML is a **static pod** the kubelet watches and runs:
- `kube-apiserver.yaml`
- `kube-controller-manager.yaml`
- `kube-scheduler.yaml`
- `etcd.yaml`

```bash
sudo systemctl status kubelet --no-pager | head
sudo systemctl status containerd --no-pager | head
```

`kubelet` and `containerd` run as systemd services, not pods.

---

## Step 2 — Break the API server

```bash
sudo sed -i 's|--secure-port=6443|--secure-port=6444|' /etc/kubernetes/manifests/kube-apiserver.yaml
```

Within ~20 s the kubelet re-creates the pod with the bad port.

```bash
kubectl get nodes
# error: dial tcp 127.0.0.1:6443: connect: connection refused
```

---

## Step 3 — Diagnose

The API is gone, so use container-level tools.

```bash
sudo crictl ps -a | grep apiserver
sudo crictl logs $(sudo crictl ps -a | grep apiserver | awk '{print $1}' | head -1) 2>&1 | tail -20
sudo journalctl -u kubelet --no-pager | tail -30
```

---

## Step 4 — Fix

```bash
sudo sed -i 's|--secure-port=6444|--secure-port=6443|' /etc/kubernetes/manifests/kube-apiserver.yaml
```

Wait ~30 s for the kubelet to rotate the static pod.

```bash
kubectl get nodes
```

---

## Step 5 — etcd health

```bash
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health
```

`Healthy` is the only acceptable output for a healthy single-node etcd.

---

## Step 6 — Controller-manager and scheduler

```bash
kubectl -n kube-system logs $(kubectl -n kube-system get pod -l component=kube-controller-manager -o name) | tail
kubectl -n kube-system logs $(kubectl -n kube-system get pod -l component=kube-scheduler -o name) | tail
```

Look for `leaderelection lost` or `connection refused to apiserver`.

---

## Step 7 — Cheat sheet

| Symptom                              | Look at                                                      |
|--------------------------------------|--------------------------------------------------------------|
| `kubectl` hangs / `connection refused`| `/var/log/pods/kube-system_kube-apiserver-*`, `crictl logs` |
| Nodes stuck `NotReady`               | `journalctl -u kubelet`, `journalctl -u containerd`          |
| Pods stuck `Pending`                 | kube-scheduler logs                                          |
| New ReplicaSet not creating pods     | kube-controller-manager logs                                 |
| Persistent data missing / inconsistent | etcd logs + `etcdctl endpoint status --write-out=table`     |

---

## What you learned
- Static-pod manifest path: `/etc/kubernetes/manifests/`.
- Use `crictl` and `journalctl` when `kubectl` is unavailable.
- The control-plane → on-disk → log mapping for fast triage.
