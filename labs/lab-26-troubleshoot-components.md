# Lab 26 — Troubleshoot Cluster Components

Troubleshooting is the highest-weighted CKA 2026 domain at 30%. This lab covers diagnosing and fixing broken control plane components: the API server, controller manager, scheduler, and etcd. When `kubectl` is unresponsive, you must use `crictl` and `journalctl` instead.

Run on https://killercoda.com/playgrounds/scenario/kubeadm

**Required software (free):**
- `kubectl`, `crictl`, `journalctl` (pre-installed on Killercoda kubeadm playground)
- `etcdctl` (pre-installed on Killercoda)

---

## Step 1 — Know where control plane components live

```bash
ls /etc/kubernetes/manifests/
```

Static pod manifests (watched by kubelet — changes auto-restart the component):
- `kube-apiserver.yaml`
- `kube-controller-manager.yaml`
- `kube-scheduler.yaml`
- `etcd.yaml`

```bash
sudo systemctl status kubelet --no-pager | head -5
sudo systemctl status containerd --no-pager | head -5
```

kubelet and containerd run as **systemd services**, not static pods.

---

## Step 2 — Break the API server (intentional fault)

```bash
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kube-apiserver-backup.yaml
sudo sed -i 's/--secure-port=6443/--secure-port=9999/' /etc/kubernetes/manifests/kube-apiserver.yaml
```

kubectl is now broken:

```bash
kubectl get nodes 2>&1 | head -3
```

---

## Step 3 — Diagnose with crictl (when kubectl is down)

```bash
sudo crictl ps -a | grep apiserver
sudo crictl logs $(sudo crictl ps -a | grep apiserver | awk '{print $1}') 2>&1 | tail -10
```

Look for the port binding error. Also check kubelet events:

```bash
sudo journalctl -u kubelet --since "2 minutes ago" | grep -i "apiserver\|error\|fail" | tail -10
```

---

## Step 4 — Fix the API server

```bash
sudo cp /tmp/kube-apiserver-backup.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
```

Kubelet detects the file change and restarts the static pod automatically. Wait ~30 seconds:

```bash
until kubectl get nodes 2>/dev/null; do echo "waiting for API..."; sleep 5; done
```

---

## Step 5 — Check etcd health

```bash
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health
```

Expected: `127.0.0.1:2379 is healthy`

---

## Step 6 — etcd backup and restore (always tested in CKA)

**Backup:**
```bash
sudo ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /tmp/etcd-backup.db
sudo ETCDCTL_API=3 etcdctl snapshot status /tmp/etcd-backup.db
```

**Restore (reference — do not run on a live cluster):**
```bash
# Stop etcd first, then:
sudo ETCDCTL_API=3 etcdctl snapshot restore /tmp/etcd-backup.db \
  --data-dir=/var/lib/etcd-restore
# Update etcd static pod --data-dir to point to /var/lib/etcd-restore
```

---

## Step 7 — Triage reference table

| Symptom | Tool | Command |
|---------|------|---------|
| `kubectl` hangs | crictl | `sudo crictl logs <apiserver-container-id>` |
| Node `NotReady` | journalctl | `sudo journalctl -u kubelet -n 50` |
| Pods stuck `Pending` | kubectl | `kubectl describe pod <name>` → Events |
| Scheduler broken | crictl | `sudo crictl logs <scheduler-container-id>` |
| Controller broken | crictl | `sudo crictl logs <controller-manager-id>` |
| etcd unhealthy | etcdctl | `etcdctl endpoint health` |

---

## Free online tools

- **Troubleshooting clusters**: https://kubernetes.io/docs/tasks/debug/debug-cluster/
- **etcdctl docs**: https://etcd.io/docs/v3.5/op-guide/etcdctl/
- **Static pods docs**: https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/
- **killer.sh** — CKA mock exam: https://killer.sh
- **Kubernetes docs** (allowed in CKA exam): https://kubernetes.io/docs/

---

## What you learned

- Static pod manifests in `/etc/kubernetes/manifests/` — kubelet auto-restarts on file change.
- `crictl ps -a` and `crictl logs` replace `kubectl logs` when the API server is down.
- `journalctl -u kubelet` shows kubelet-level errors including CRI and static pod failures.
- `etcdctl snapshot save` backs up etcd — memorise the cert flags for the exam.
- etcd backup/restore is tested in virtually every CKA sitting.
