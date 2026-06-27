# Lab 1 — kubeadm Prerequisites: Kernel Modules, containerd, and Kubernetes Binaries v1.35

Before you can bootstrap a Kubernetes cluster with kubeadm, every node must satisfy a strict set of prerequisites. This lab walks you through disabling swap, loading the required kernel modules, configuring system parameters, installing containerd as the container runtime, and finally installing kubeadm, kubelet, and kubectl at version v1.35. Getting these steps right is the foundation for Labs 2–5 and reflects exactly what the CKA exam expects you to know about cluster installation.

Run on https://killercoda.com/playgrounds/scenario/kubeadm

**Required software (free):**
- containerd (install command below)
- kubeadm v1.35 (install command below)
- kubelet v1.35 (install command below)
- kubectl v1.35 (install command below)

---

## Step 1 — Verify OS and Disable Swap

```bash
# Check OS release
cat /etc/os-release

# Disable swap immediately (required by kubelet)
swapoff -a

# Persist across reboots — comment out swap entries
sed -i '/\bswap\b/d' /etc/fstab

# Confirm swap is off
free -h | grep -i swap
# Swap line should show: 0B  0B  0B
```

Kubernetes kubelet will refuse to start if swap is enabled. The `sed` command ensures swap stays disabled after a reboot by removing it from `/etc/fstab`.

---

## Step 2 — Load Required Kernel Modules

```bash
# Create a module-load config file for Kubernetes
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# Load the modules immediately without rebooting
modprobe overlay
modprobe br_netfilter

# Verify both modules are loaded
lsmod | grep -E 'overlay|br_netfilter'
```

`overlay` is required by containerd for its overlay filesystem. `br_netfilter` enables iptables to see bridged traffic, which is essential for pod-to-pod networking via kube-proxy.

---

## Step 3 — Configure Kernel Network Parameters (sysctl)

```bash
# Write sysctl settings required by Kubernetes
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply without rebooting
sysctl --system

# Verify the values are set
sysctl net.ipv4.ip_forward
sysctl net.bridge.bridge-nf-call-iptables
```

`ip_forward` allows the node to route packets between interfaces (pod CIDR → node NIC). The bridge settings allow iptables rules to intercept traffic crossing Linux bridges, which is how CNI plugins enforce network policies.

---

## Step 4 — Install containerd

```bash
# Install required packages
apt-get update && apt-get install -y ca-certificates curl gnupg

# Add Docker's official GPG key (containerd is distributed via Docker repos)
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add the Docker apt repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y containerd.io
```

containerd is the CRI (Container Runtime Interface) that Kubernetes v1.35 uses to pull and run containers. Docker Engine is no longer required — containerd alone is sufficient.

---

## Step 5 — Configure containerd with SystemdCgroup

```bash
# Generate the default config
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml

# Switch cgroup driver to systemd (must match kubelet's cgroup driver)
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' \
  /etc/containerd/config.toml

# Verify the change
grep 'SystemdCgroup' /etc/containerd/config.toml
# Expected: SystemdCgroup = true

# Restart and enable containerd
systemctl restart containerd
systemctl enable containerd
systemctl status containerd --no-pager
```

The cgroup driver mismatch between containerd and kubelet is one of the most common cluster bootstrap failures on the CKA exam. Both MUST use `systemd`. The default config uses `cgroupfs` — always override it.

---

## Step 6 — Verify crictl Talks to containerd

```bash
# Install crictl (Container Runtime Interface CLI)
VERSION="v1.35.0"
curl -L https://github.com/kubernetes-sigs/cri-tools/releases/download/${VERSION}/crictl-${VERSION}-linux-amd64.tar.gz \
  | tar -C /usr/local/bin -xz

# Configure crictl to use containerd's socket
cat <<EOF | tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 2
debug: false
EOF

# Test crictl
crictl info
crictl images
```

`crictl` is the debug tool to use when `kubectl` is unavailable (e.g., before the cluster is bootstrapped, or when the API server is down). CKA exam expects you to know crictl commands.

---

## Step 7 — Add the Kubernetes apt Repository

```bash
# Install prerequisite packages
apt-get install -y apt-transport-https ca-certificates curl gpg

# Download the Kubernetes signing key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | \
  gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add the Kubernetes v1.35 repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | \
  tee /etc/apt/sources.list.d/kubernetes.list

apt-get update

# Verify the packages are available at v1.35
apt-cache madison kubeadm | head -5
```

Kubernetes maintains separate apt repositories per minor version. Using `v1.35` in the URL pins you to that version family. On the CKA exam the repository is often pre-configured; verify with `apt-cache madison`.

---

## Step 8 — Install kubeadm, kubelet, kubectl at v1.35

```bash
# Install the three binaries
apt-get install -y kubeadm=1.35.0-* kubelet=1.35.0-* kubectl=1.35.0-*

# Hold them at this version to prevent accidental apt-get upgrade
apt-mark hold kubeadm kubelet kubectl

# Verify versions
kubeadm version
kubelet --version
kubectl version --client
```

`apt-mark hold` prevents unintentional upgrades. On the CKA exam, when you perform an upgrade in Lab 4, you must explicitly `apt-mark unhold` before installing the newer version.

---

## Step 9 — Enable kubelet Service (Do Not Start Yet)

```bash
# Enable kubelet so it starts automatically after kubeadm init
systemctl enable kubelet

# kubelet will fail to start in a loop until kubeadm init runs
# This is normal — it is waiting for the cluster config
systemctl status kubelet --no-pager || true
```

The kubelet enters a crash-restart loop until `kubeadm init` or `kubeadm join` provides its configuration. This is expected behavior — do not troubleshoot it at this stage.

---

## Step 10 — Pre-pull Control Plane Images

```bash
# Pull required images before init (speeds up bootstrap, works offline)
kubeadm config images pull --kubernetes-version=v1.35.0

# List the pulled images
crictl images | grep registry.k8s.io

# Expected images:
# registry.k8s.io/kube-apiserver:v1.35.0
# registry.k8s.io/kube-controller-manager:v1.35.0
# registry.k8s.io/kube-scheduler:v1.35.0
# registry.k8s.io/kube-proxy:v1.35.0
# registry.k8s.io/etcd:3.5.x
# registry.k8s.io/coredns/coredns:v1.11.x
# registry.k8s.io/pause:3.x
```

Pre-pulling images is useful in exam environments with slow internet. The `pause` container is the "infra" container that holds network namespaces for every pod.

---

## Step 11 — Final Node Readiness Check

```bash
# All-in-one pre-flight check
echo "=== Swap ==="
free -h | grep Swap

echo "=== Kernel modules ==="
lsmod | grep -E 'overlay|br_netfilter'

echo "=== sysctl ==="
sysctl net.ipv4.ip_forward net.bridge.bridge-nf-call-iptables

echo "=== containerd ==="
systemctl is-active containerd

echo "=== Binary versions ==="
kubeadm version -o short
kubelet --version
kubectl version --client -o yaml | grep gitVersion

echo "=== CRI socket ==="
ls -la /run/containerd/containerd.sock
```

Run this checklist before executing `kubeadm init` in Lab 2. Every item must pass; any failure here will cause kubeadm preflight checks to abort.

---

## Free online tools
- **Kubernetes Docs** — official reference (allowed in CKA exam): https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
- **killer.sh** — CKA mock exam environment: https://killer.sh
- **Killercoda kubeadm playground** — free kubeadm cluster sandbox: https://killercoda.com/playgrounds/scenario/kubeadm
- **containerd releases** — GitHub release page: https://github.com/containerd/containerd/releases
- **cri-tools releases** — crictl downloads: https://github.com/kubernetes-sigs/cri-tools/releases

---

## What you learned
- Swap must be permanently disabled before kubelet will run; `swapoff -a` + edit `/etc/fstab`
- `overlay` and `br_netfilter` kernel modules are required for every Kubernetes node
- sysctl settings `net.ipv4.ip_forward` and `bridge-nf-call-iptables` must equal `1`
- containerd's `SystemdCgroup = true` must match kubelet's cgroup driver or cluster bootstrap fails
- `crictl` is the go-to debug tool when `kubectl` is unavailable — configure it via `/etc/crictl.yaml`
- Kubernetes binaries are installed from version-specific apt repos (`pkgs.k8s.io/core:/stable:/v1.35`)
- `apt-mark hold` prevents accidental version upgrades; unhold before performing a planned upgrade
- Pre-pulling images with `kubeadm config images pull` speeds up cluster bootstrap
- The kubelet crash loop before `kubeadm init` is normal, not an error condition
