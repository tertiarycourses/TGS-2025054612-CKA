# Lab 1 — kubeadm Prerequisites and Container Runtime

In this lab you will prepare two clean Ubuntu nodes for a Kubernetes cluster install. You will load the required kernel modules, set the right sysctls, install `containerd` as the Container Runtime Interface (CRI), and install the `kubeadm`, `kubelet`, and `kubectl` binaries from the official Kubernetes apt repository.

Run this lab on the **kubeadm playground** (two Ubuntu VMs already wired together):
https://killercoda.com/playgrounds/scenario/kubeadm

The playground gives you `controlplane` and `node01` shells. Repeat every step on **both** nodes unless stated otherwise.

---

## Step 1 — Load kernel modules

The Kubernetes networking stack needs the `br_netfilter` and `overlay` kernel modules.

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
```

`overlay` powers the containerd snapshotter; `br_netfilter` lets iptables see bridged traffic so kube-proxy can NAT it.

---

## Step 2 — Set required sysctls

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system
```

`ip_forward=1` is mandatory: pods on different nodes route through the host.

---

## Step 3 — Disable swap

`kubelet` refuses to start if swap is on (unless you opt in via KubeletConfiguration).

```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

---

## Step 4 — Install containerd

```bash
sudo apt update
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
```

`SystemdCgroup = true` aligns containerd's cgroup driver with the kubelet default — mismatched drivers are the #1 cause of "node NotReady" in fresh clusters.

---

## Step 5 — Install kubeadm, kubelet, kubectl

```bash
sudo apt install -y apt-transport-https ca-certificates curl gpg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

`apt-mark hold` pins the versions so a stray `apt upgrade` cannot break your cluster mid-term.

---

## Step 6 — Verify

```bash
kubeadm version
kubectl version --client
sudo systemctl status containerd --no-pager | head
sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock version
```

You should see kubeadm v1.31.x, containerd active, and crictl reporting the runtime version.

---

## What you learned
- The exact kernel modules and sysctls kubeadm needs.
- Why `SystemdCgroup=true` matters for containerd.
- How to install the pinned Kubernetes apt packages from `pkgs.k8s.io`.
