#!/bin/bash
# Provision a single-node v1.34 Kubernetes cluster in the background.
# Runs while the student reads the intro — cluster is ready by Step 1.
set -e

# ── kernel prereqs ────────────────────────────────────────────────────────────
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# ── containerd ────────────────────────────────────────────────────────────────
apt-get update -qq
apt-get install -y -qq containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml > /dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# ── kubeadm / kubelet / kubectl at v1.34 ─────────────────────────────────────
apt-get install -y -qq apt-transport-https ca-certificates curl gpg
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | \
  gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | \
  tee /etc/apt/sources.list.d/kubernetes.list
apt-get update -qq
apt-get install -y -qq kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# ── bootstrap the control plane ───────────────────────────────────────────────
kubeadm init --pod-network-cidr=10.244.0.0/16 --kubernetes-version=v1.34.0 \
  --ignore-preflight-errors=NumCPU,Mem 2>&1 | tee /tmp/kubeadm-init.log

mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config
chmod 600 /root/.kube/config

# Allow scheduling on control-plane node (single-node cluster)
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# ── Flannel CNI ───────────────────────────────────────────────────────────────
kubectl apply -f \
  https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Signal that setup is done
touch /tmp/cluster-ready
echo "v1.34 cluster ready" > /tmp/cluster-ready
