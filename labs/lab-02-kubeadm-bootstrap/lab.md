# Lab 2 — Bootstrap a Cluster with kubeadm

In this lab you will turn the two prepared nodes from Lab 1 into a working Kubernetes cluster. You will run `kubeadm init` on the control plane, copy the admin kubeconfig, then join the worker with the bootstrap token.

**Lab environment:** [Play with Kubernetes](https://labs.play-with-k8s.com)
---

## Step 1 — Initialize the control plane

On the **controlplane** node:

```bash
sudo kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --apiserver-advertise-address=$(hostname -I | awk '{print $1}')
```

- `--pod-network-cidr` reserves a non-overlapping range for the CNI plugin (Calico's default).
- `--apiserver-advertise-address` pins the API server to the node's primary IP so workers can reach it.

`kubeadm init` runs preflight checks, generates PKI in `/etc/kubernetes/pki`, writes static-pod manifests in `/etc/kubernetes/manifests`, and prints a `kubeadm join` command at the end. **Copy that join command** — you'll need it in Step 3.

---

## Step 2 — Set up your kubeconfig

Still on **controlplane**:

```bash
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl get nodes
```

The control plane will show `NotReady` — that's expected until a CNI is installed (Lab 3).

---

## Step 3 — Join the worker

On **node01**, paste the join command from Step 1, prefixed with `sudo`:

```bash
sudo kubeadm join <CONTROLPLANE_IP>:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

If the token expired (24 h TTL), regenerate it on the control plane:

```bash
kubeadm token create --print-join-command
```

---

## Step 4 — Inspect the new cluster

Back on **controlplane**:

```bash
kubectl get nodes -o wide
kubectl get pods -n kube-system
```

You should see two nodes (both `NotReady`) and the static control-plane pods running: `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, `etcd`, plus `kube-proxy` and `coredns`. The CoreDNS pods will stay `Pending` until a CNI is up.

---

## Step 5 — Explore what kubeadm built

```bash
ls /etc/kubernetes/
ls /etc/kubernetes/manifests/
ls /etc/kubernetes/pki/
```

- `manifests/*.yaml` — static pod definitions watched by kubelet.
- `pki/` — the CA, API server, etcd, and service-account keys.
- `admin.conf`, `controller-manager.conf`, `scheduler.conf`, `kubelet.conf` — kubeconfigs for each component.

---

## What you learned
- What `kubeadm init` produces on disk.
- How the worker authenticates with a bootstrap token + CA hash.
- Why nodes are `NotReady` until a CNI plugin runs.
