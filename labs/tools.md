# CKA 2026 — Tool Reference

## Section A — Pre-installed on Killercoda (no setup required)

| Tool | Version | Purpose |
|------|---------|---------|
| `kubectl` | v1.35 | Cluster control — the primary exam tool |
| `kubeadm` | v1.35 | Cluster bootstrap and upgrade |
| `kubelet` | v1.35 | Node agent (systemd service) |
| `containerd` | latest | Container runtime |
| `crictl` | latest | Low-level CRI debugging (use when kubectl is down) |
| `etcdctl` | v3.5 | etcd backup/restore |
| `helm` | v3 | Kubernetes package manager |
| `openssl` | system | TLS cert generation for Ingress labs |
| `journalctl` | system | systemd log reader |
| `iptables` | system | kube-proxy rule inspection |
| `systemctl` | system | Service management (kubelet, containerd) |
| `curl` | system | HTTP connectivity testing |
| `jq` | system | JSON processing |
| `vim` / `nano` | system | YAML editing in the exam |

---

## Section B — Installed during labs (one-command setup)

| Tool | Install Command | Purpose |
|------|----------------|---------|
| `metrics-server` | `kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml` | Powers `kubectl top` |
| `ingress-nginx` | `kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml` | Ingress controller |
| `local-path-provisioner` | `kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml` | Dynamic PV provisioner |
| Gateway API CRDs | `kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml` | Gateway API CRDs |
| `stern` | `curl -sL .../stern_linux_amd64.tar.gz \| tar xz && sudo mv stern /usr/local/bin/` | Multi-pod log tailing |
| `helm` (if missing) | `curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \| bash` | Helm CLI |

---

## Section C — Browser / free online tools

| Tool | URL | Purpose |
|------|-----|---------|
| Killercoda Kubernetes | https://killercoda.com/playgrounds/scenario/kubernetes | Multi-node lab environment |
| Killercoda kubeadm | https://killercoda.com/playgrounds/scenario/kubeadm | Cluster bootstrap labs |
| killer.sh | https://killer.sh | Official CKA mock exam (2 free attempts with exam purchase) |
| Kubernetes docs | https://kubernetes.io/docs/ | Allowed reference during the exam |
| etcd docs | https://etcd.io/docs/ | Allowed reference during the exam |
| Helm docs | https://helm.sh/docs/ | Allowed reference during the exam |
| NetworkPolicy editor | https://editor.networkpolicy.io | Visual NetworkPolicy builder |
| Lens Desktop | https://k8slens.dev | GUI Kubernetes IDE (not usable in exam) |
| Play with Kubernetes | https://labs.play-with-k8s.com | Free 4-hour cluster sessions |

---

## Exam-day setup (first thing after the exam starts)

```bash
# Autocomplete and alias — saves significant time
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
alias k=kubectl
complete -o default -F __start_kubectl k
export do="--dry-run=client -o yaml"
export now="--force --grace-period=0"

# Confirm current context
kubectl config current-context
kubectl get nodes
```

---

## Critical kubectl shortcuts for the exam

```bash
# Generate YAML without applying (memorise $do)
kubectl run nginx --image=nginx $do
kubectl create deployment web --image=nginx --replicas=3 $do

# Explain any field
kubectl explain pod.spec.containers.resources
kubectl explain networkpolicy.spec.ingress

# Force delete a stuck pod (memorise $now)
kubectl delete pod stuck-pod $now

# Check permissions
kubectl auth can-i list pods --as=system:serviceaccount:default:my-sa

# Switch namespace for all subsequent commands
kubectl config set-context --current --namespace=kube-system
kubectl config set-context --current --namespace=default

# Quickly copy a resource and edit
kubectl get svc existing-svc -o yaml | sed 's/existing-svc/new-svc/' | kubectl apply -f -
```

---

## etcd backup/restore (always in the exam)

```bash
# Backup
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /tmp/etcd-backup.db

# Verify
ETCDCTL_API=3 etcdctl snapshot status /tmp/etcd-backup.db

# Restore (run on control-plane node, etcd must be stopped first)
ETCDCTL_API=3 etcdctl snapshot restore /tmp/etcd-backup.db \
  --data-dir=/var/lib/etcd-restore
# Then update etcd static pod manifest: --data-dir=/var/lib/etcd-restore
```

---

## Cluster upgrade sequence (kubeadm)

```bash
# Control plane
sudo apt-mark unhold kubeadm && sudo apt-get install -y kubeadm=1.35.x-* && sudo apt-mark hold kubeadm
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v1.35.x
sudo apt-mark unhold kubelet kubectl && sudo apt-get install -y kubelet=1.35.x-* kubectl=1.35.x-* && sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload && sudo systemctl restart kubelet

# Worker node (run on control-plane)
kubectl drain node01 --ignore-daemonsets --delete-emptydir-data
# SSH to node01
sudo apt-mark unhold kubeadm && sudo apt-get install -y kubeadm=1.35.x-* && sudo apt-mark hold kubeadm
sudo kubeadm upgrade node
sudo apt-mark unhold kubelet kubectl && sudo apt-get install -y kubelet=1.35.x-* kubectl=1.35.x-* && sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload && sudo systemctl restart kubelet
# Back on control-plane
kubectl uncordon node01
```

---

## API versions for CKA 2026 (Kubernetes v1.35)

| Resource | apiVersion |
|----------|-----------|
| Pod, Service, PV, PVC, ConfigMap, Secret | `v1` |
| Deployment, DaemonSet, StatefulSet, ReplicaSet | `apps/v1` |
| CronJob, Job | `batch/v1` |
| Ingress | `networking.k8s.io/v1` |
| NetworkPolicy | `networking.k8s.io/v1` |
| Gateway, HTTPRoute | `gateway.networking.k8s.io/v1` |
| HPA | `autoscaling/v2` |
| PodDisruptionBudget | `policy/v1` |
| ClusterRole, Role, ClusterRoleBinding, RoleBinding | `rbac.authorization.k8s.io/v1` |
| StorageClass | `storage.k8s.io/v1` |
| CustomResourceDefinition | `apiextensions.k8s.io/v1` |
