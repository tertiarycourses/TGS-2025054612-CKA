# Lab 2 — kubeadm Bootstrap: init, kubeconfig, Worker Join, and Cluster PKI

With prerequisites satisfied from Lab 1, this lab runs `kubeadm init` to create the control plane, sets up `kubectl` access via kubeconfig, joins a worker node using the token-based join command, and explores the PKI certificates that kubeadm generates under `/etc/kubernetes/pki/`. Understanding the cluster PKI is directly tested in the CKA exam when troubleshooting TLS errors or rotating certificates.

Run on https://killercoda.com/playgrounds/scenario/kubeadm

**Required software (free):**
- kubeadm v1.35 (from Lab 1)
- kubelet v1.35 (from Lab 1)
- kubectl v1.35 (from Lab 1)
- containerd (from Lab 1)

---

## Step 1 — Plan the Cluster Network CIDRs

```bash
# Decide on pod and service CIDRs before running init
# These must not overlap with your node network

# Common choices:
# Pod CIDR:     10.244.0.0/16  (Flannel default)
# Pod CIDR:     192.168.0.0/16 (Calico default) — used in this lab
# Service CIDR: 10.96.0.0/12   (kubeadm default)

# Check your node's IP address
ip addr show | grep 'inet ' | grep -v 127.0.0.1

# Note the control-plane node IP (e.g., 172.30.1.2)
CONTROL_PLANE_IP=$(hostname -I | awk '{print $1}')
echo "Control plane IP: $CONTROL_PLANE_IP"
```

Choosing the pod CIDR before init is critical — it cannot be changed without rebuilding the cluster. The pod CIDR must not overlap with the node network or the service CIDR.

---

## Step 2 — Run kubeadm init

```bash
# Initialize the control plane
# --pod-network-cidr must match what your CNI plugin expects
# --kubernetes-version pins the exact version
kubeadm init \
  --kubernetes-version=v1.35.0 \
  --pod-network-cidr=192.168.0.0/16 \
  --service-cidr=10.96.0.0/12 \
  --apiserver-advertise-address=$(hostname -I | awk '{print $1}')

# The output will end with something like:
# Your Kubernetes control-plane has initialized successfully!
# ...
# kubeadm join 172.30.1.2:6443 --token abc123.xyz \
#   --discovery-token-ca-cert-hash sha256:aaabbb...
```

`kubeadm init` runs preflight checks, generates PKI, starts static pod manifests, waits for the API server, configures RBAC, and prints the join command. Save the join command — you need it for worker nodes.

---

## Step 3 — Configure kubectl Access (kubeconfig)

```bash
# Set up kubectl for the current user (run as root or regular user)
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Verify kubectl works
kubectl version
kubectl cluster-info
kubectl get nodes
# STATUS will be NotReady until CNI is installed (Lab 3)
```

`/etc/kubernetes/admin.conf` contains credentials for the `kubernetes-admin` cluster-admin user. On the CKA exam, the kubeconfig is usually pre-configured — but you must know where it lives and how to set `KUBECONFIG` if using a non-default path.

---

## Step 4 — Explore the kubeconfig Structure

```bash
# View the kubeconfig file structure
kubectl config view

# Show current context
kubectl config current-context

# List all contexts
kubectl config get-contexts

# Show clusters, users, contexts separately
kubectl config get-clusters
kubectl config get-users

# Switch context (useful when managing multiple clusters)
# kubectl config use-context <context-name>

# Set KUBECONFIG environment variable to use a different config
# export KUBECONFIG=/path/to/other.conf
```

The CKA exam provides a multi-cluster kubeconfig and asks you to work in specific contexts. Always run `kubectl config use-context <name>` at the start of each exam question to ensure you're in the right cluster.

---

## Step 5 — Explore the Static Pod Manifests

```bash
# Static pods are managed directly by kubelet, not the API server
# They live in /etc/kubernetes/manifests/
ls -la /etc/kubernetes/manifests/

# View the kube-apiserver static pod manifest
cat /etc/kubernetes/manifests/kube-apiserver.yaml | head -60

# Key flags to know:
grep -E 'advertise-address|service-cluster-ip-range|etcd-servers|tls-cert' \
  /etc/kubernetes/manifests/kube-apiserver.yaml

# View all control plane component manifests
for f in /etc/kubernetes/manifests/*.yaml; do
  echo "=== $f ==="
  grep 'image:' "$f"
done
```

Static pod manifests in `/etc/kubernetes/manifests/` are watched by kubelet. Editing a manifest causes kubelet to restart the corresponding pod automatically — this is how you modify API server flags on the CKA exam.

---

## Step 6 — Explore the Cluster PKI

```bash
# kubeadm generates all certificates under /etc/kubernetes/pki/
ls -la /etc/kubernetes/pki/

# View the CA certificate details
openssl x509 -in /etc/kubernetes/pki/ca.crt -noout -text | head -30

# Check certificate expiry for all certs
kubeadm certs check-expiration

# View individual component certificates
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout \
  -subject -issuer -dates

# View etcd PKI (separate CA)
ls /etc/kubernetes/pki/etcd/
openssl x509 -in /etc/kubernetes/pki/etcd/ca.crt -noout -dates
```

kubeadm creates a dedicated CA for etcd separate from the main cluster CA. Certificates are valid for 1 year (except the CA which is 10 years). The CKA exam may test `kubeadm certs renew all`.

---

## Step 7 — Generate a New Join Token

```bash
# If the original join token expired (24-hour TTL), create a new one
kubeadm token create --print-join-command

# List current tokens
kubeadm token list

# Create a token with a longer TTL (for testing)
kubeadm token create --ttl 2h --print-join-command

# Get the CA cert hash separately
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
  openssl rsa -pubin -outform der 2>/dev/null | \
  openssl dgst -sha256 -hex | sed 's/^.* //'
```

Join tokens expire after 24 hours by default. On the CKA exam, if you need to join a worker after the initial token expires, use `kubeadm token create --print-join-command`.

---

## Step 8 — Join a Worker Node

```bash
# Run this command ON THE WORKER NODE
# Replace with the actual token and hash from Step 2 or 7

# On the control plane, get the join command:
kubeadm token create --print-join-command

# On the WORKER NODE (run the output of the above command):
kubeadm join 172.30.1.2:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>

# Back on the CONTROL PLANE, verify the worker joined:
kubectl get nodes -o wide
# Both nodes should appear (STATUS=NotReady until CNI installed)
```

The join command uses a Bootstrap Token to authenticate and downloads the cluster CA cert, kubelet credentials, and configuration. Once joined, the node appears in `kubectl get nodes` immediately.

---

## Step 9 — Inspect etcd

```bash
# etcd is the cluster's key-value store — ALL cluster state lives here
# Install etcdctl
ETCD_VER=$(kubectl -n kube-system get pod -l component=etcd \
  -o jsonpath='{.items[0].spec.containers[0].image}' | cut -d: -f2)
echo "etcd version: $ETCD_VER"

# Use etcdctl via the etcd pod (no installation needed)
kubectl -n kube-system exec -it etcd-$(hostname) -- \
  etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health

# List some keys stored in etcd
kubectl -n kube-system exec -it etcd-$(hostname) -- \
  etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get / --prefix --keys-only | head -30
```

etcd health is critical for cluster stability. The CKA exam always tests `etcdctl snapshot save` and `etcdctl snapshot restore`. The three TLS flags (`--cacert`, `--cert`, `--key`) are always required when talking to etcd.

---

## Step 10 — Take an etcd Snapshot (Backup)

```bash
# IMPORTANT: etcd backup/restore is guaranteed to appear on CKA exam

# Set environment variables to avoid repeating flags
export ETCDCTL_API=3
export ETCDCTL_ENDPOINTS=https://127.0.0.1:2379
export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt
export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt
export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key

# Take a snapshot
etcdctl snapshot save /opt/etcd-backup-$(date +%Y%m%d).db

# Verify the snapshot
etcdctl snapshot status /opt/etcd-backup-$(date +%Y%m%d).db \
  --write-out=table

# Output shows:
# HASH | REVISION | TOTAL KEYS | TOTAL SIZE
```

Always set `ETCDCTL_API=3` — API v2 is deprecated. The snapshot file is a portable backup of all Kubernetes state. Store it outside the cluster (e.g., NFS, S3, local disk on a different node).

---

## Step 11 — Verify Cluster Component Health

```bash
# Check all system pods
kubectl get pods -n kube-system

# Check component status (deprecated in newer versions but still useful)
kubectl get componentstatuses 2>/dev/null || echo "Use etcd endpoint health instead"

# Check kubelet status on each node
systemctl status kubelet --no-pager

# View kubelet logs
journalctl -u kubelet --no-pager -n 50

# Check API server is responding
kubectl get --raw /metrics | head -50

```

The API server exposes `/healthz`, `/readyz`, and `/livez` endpoints. These are useful for diagnosing startup issues when the API server is partially functional.

---

## Free online tools
- **Kubernetes Docs — kubeadm init**: https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/
- **Kubernetes Docs — PKI certificates**: https://kubernetes.io/docs/setup/best-practices/certificates/
- **killer.sh** — CKA mock exam: https://killer.sh
- **Killercoda kubeadm playground**: https://killercoda.com/playgrounds/scenario/kubeadm
- **etcd docs** — backup and restore: https://etcd.io/docs/v3.5/op-guide/recovery/

---

## What you learned
- `kubeadm init` generates PKI, starts static pods, and prints the worker join command
- kubeconfig is stored at `/etc/kubernetes/admin.conf`; copy to `~/.kube/config` for kubectl access
- Static pod manifests in `/etc/kubernetes/manifests/` are watched by kubelet — edit them to change API server flags
- The cluster PKI lives in `/etc/kubernetes/pki/`; etcd has its own separate CA under `/etc/kubernetes/pki/etcd/`
- `kubeadm certs check-expiration` shows certificate expiry dates
- Bootstrap tokens expire after 24 hours; regenerate with `kubeadm token create --print-join-command`
- `etcdctl snapshot save` creates a cluster backup — requires all three TLS flags
- Always set `ETCDCTL_API=3` when using etcdctl
- Nodes show `NotReady` until a CNI plugin is installed (Lab 3)
- The CKA exam always includes at least one etcd backup/restore question
