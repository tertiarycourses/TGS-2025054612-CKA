# Lab 10 — Extension Interfaces (CNI, CSI, CRI)

Kubernetes plugs into the host via three standard interfaces:
- **CRI** — Container Runtime Interface (containerd, CRI-O)
- **CNI** — Container Network Interface (Calico, Cilium, Flannel)
- **CSI** — Container Storage Interface (AWS EBS, GCE PD, local-path, Ceph)

In this lab you inspect each one on a running cluster.

**Lab environment:** *(link to be added)*
---

## Step 1 — CRI: talk to the runtime directly

`kubelet` talks to the runtime over a Unix socket. `crictl` is the debug client.

```bash
sudo crictl info | head -20
sudo crictl ps
sudo crictl images | head
```

Inspect the kubelet's runtime endpoint:

```bash
sudo cat /var/lib/kubelet/config.yaml | grep -E "runtime|cgroup"
ls /etc/crictl.yaml /run/containerd/containerd.sock 2>/dev/null
```

---

## Step 2 — CNI: where the network plugin lives

```bash
ls /etc/cni/net.d/
ls /opt/cni/bin/
```

`/etc/cni/net.d/*.conflist` is the active CNI config. `/opt/cni/bin/` holds the plugin binaries. The kubelet calls these binaries every time a pod is created or deleted.

Look at the live CNI config:

```bash
cat /etc/cni/net.d/*.conflist | head -40
```

---

## Step 3 — CSI: list installed drivers

```bash
kubectl get csidrivers
kubectl get csinodes
kubectl get storageclasses
```

On a stock Killercoda cluster you'll usually see `rancher.io/local-path` (Rancher's local-path provisioner). Each CSI driver registers itself with the kubelet via the **CSI plugin socket** at `/var/lib/kubelet/plugins/<driver>/csi.sock`.

```bash
sudo ls /var/lib/kubelet/plugins/ 2>/dev/null
sudo ls /var/lib/kubelet/plugins_registry/ 2>/dev/null
```

---

## Step 4 — Trace a pod through all three interfaces

```bash
kubectl run demo --image=nginx
kubectl wait --for=condition=Ready pod/demo --timeout=60s

# CRI side
sudo crictl ps | grep demo

# CNI side
kubectl get pod demo -o jsonpath='{.status.podIP}{"\n"}'

# CSI side (no storage attached, but show the node's allocatable)
kubectl describe csinode $(hostname)
```

Tear down:

```bash
kubectl delete pod demo
```

---

## Step 5 — Read the CRI socket type from the kubelet config

```bash
sudo grep -E "containerRuntimeEndpoint|imageServiceEndpoint" /var/lib/kubelet/config.yaml
```

On modern clusters the value is `unix:///run/containerd/containerd.sock`.

---

## What you learned
- Three standard plug-points: CRI, CNI, CSI.
- The on-disk locations and sockets that each interface uses.
- How to read the running configuration with `crictl`, `kubectl get csidrivers`, and the kubelet config file.
