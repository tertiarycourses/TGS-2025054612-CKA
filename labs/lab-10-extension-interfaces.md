# Lab 10 — Extension Interfaces: CRI (crictl), CNI (/etc/cni/net.d, /opt/cni/bin), CSI (kubectl get csidrivers)

Kubernetes defines three standard extension interfaces: CRI (Container Runtime Interface) for running containers, CNI (Container Network Interface) for pod networking, and CSI (Container Storage Interface) for persistent volumes. This lab explores each interface using its native debugging tools — crictl for the CRI, config file inspection for CNI, and kubectl for CSI drivers. Understanding these interfaces lets you troubleshoot at the runtime level when kubectl reports pods stuck in ContainerCreating or volumes failing to mount.

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- crictl (pre-installed or install: `VERSION=v1.35.0; curl -L https://github.com/kubernetes-sigs/cri-tools/releases/download/${VERSION}/crictl-${VERSION}-linux-amd64.tar.gz | tar -C /usr/local/bin -xz`)
- kubectl v1.35 (pre-installed)

---

## Step 1 — Understand the Kubernetes Extension Interface Architecture

```bash
# Kubernetes uses three pluggable interfaces:
#
# CRI (Container Runtime Interface)
#   - Protocol: gRPC over Unix socket
#   - Purpose: Run, stop, inspect containers and images
#   - Implementations: containerd, CRI-O
#   - Socket: /run/containerd/containerd.sock
#             /var/run/crio/crio.sock
#
# CNI (Container Network Interface)
#   - Protocol: JSON config + executable binary
#   - Purpose: Set up pod network namespaces and IP addresses
#   - Config:  /etc/cni/net.d/
#   - Bins:    /opt/cni/bin/
#
# CSI (Container Storage Interface)
#   - Protocol: gRPC
#   - Purpose: Provision and attach persistent volumes
#   - Discovery: kubectl get csidrivers

echo "All three interfaces allow swapping implementations without changing Kubernetes core"
```

The pluggable interfaces are why Kubernetes runs on bare metal with containerd, on AWS with the EBS CSI driver, and with Calico or Cilium as CNI — each is interchangeable at the interface boundary.

---

## Step 2 — Configure crictl

```bash
# crictl is the CLI for the Container Runtime Interface
# It talks directly to containerd, bypassing the kubelet and API server

# Configure crictl to find the containerd socket
cat <<'EOF' > /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
pull-image-on-create: false
EOF

# Verify crictl can connect
crictl info
# Returns JSON with containerd version, OS, etc.

# If using CRI-O instead:
# runtime-endpoint: unix:///var/run/crio/crio.sock

# Check which socket exists
ls -la /run/containerd/containerd.sock 2>/dev/null && echo "containerd found"
ls -la /var/run/crio/crio.sock 2>/dev/null && echo "crio found"
```

`/etc/crictl.yaml` tells crictl which socket to use. On the CKA exam, containerd is the standard runtime. If `crictl info` times out, check that containerd is running with `systemctl status containerd`.

---

## Step 3 — List Running Containers with crictl

```bash
# List all running pods (sandboxes in CRI terminology)
crictl pods

# List all containers
crictl ps

# List all containers including stopped ones
crictl ps -a

# List just containers in the kube-system namespace
crictl pods --namespace kube-system

# Get detailed information about a pod
SANDBOX_ID=$(crictl pods --namespace kube-system -o json | \
  python3 -c "import json,sys; d=json.load(sys.stdin); print(d['items'][0]['id'])")
crictl inspectPods $SANDBOX_ID
```

crictl's concept of "pod" maps to a "sandbox" — the pause container that holds the network namespace. Each sandbox has one or more containers running inside it.

---

## Step 4 — Inspect Images with crictl

```bash
# List all images pulled on this node
crictl images

# List images with full digests
crictl images -v

# Pull an image directly (useful when kubectl cannot reach the API server)
crictl pull nginx:alpine

# Inspect image details
crictl inspecti nginx:alpine

# Remove an image
# crictl rmi nginx:alpine

# Compare with what containerd knows directly
ctr --namespace k8s.io images list | head -10
# Note: containerd uses k8s.io namespace for Kubernetes images
```

`crictl images` and `ctr images list` both show pulled images, but crictl filters to the CRI namespace (`k8s.io`) automatically. Use `ctr` (containerd CLI) for lower-level operations.

---

## Step 5 — Inspect and Debug Containers with crictl

```bash
# Get logs from a container using crictl (works even when kubelet is down)
POD_ID=$(crictl pods --name coredns -q | head -1)
CONTAINER_ID=$(crictl ps --pod $POD_ID -q | head -1)

# Get container logs
crictl logs $CONTAINER_ID
crictl logs --tail=20 $CONTAINER_ID

# Inspect container details (equivalent to docker inspect)
crictl inspect $CONTAINER_ID

# View container process information
crictl exec -it $CONTAINER_ID /bin/sh

# Stats for all containers
crictl stats
crictl statsp  # Pod-level stats

# Stop and remove a container (use with caution — kubelet will restart it)
# crictl stop $CONTAINER_ID
# crictl rm $CONTAINER_ID
```

`crictl logs` is your backup when `kubectl logs` fails because the API server is unavailable. CKA exam troubleshooting scenarios often involve using crictl when the cluster control plane is broken.

---

## Step 6 — Inspect the CNI Configuration

```bash
# CNI plugins are configured via JSON files in /etc/cni/net.d/
ls -la /etc/cni/net.d/

# View the active CNI config (file with lowest number is used first)
# With Calico installed:
cat /etc/cni/net.d/10-calico.conflist

# With Flannel installed it would be:
# cat /etc/cni/net.d/10-flannel.conflist

# Key fields in a CNI config:
# cniVersion  — CNI spec version
# name        — name of the network
# plugins     — list of chained CNI plugins to execute
# type        — which binary to invoke from /opt/cni/bin/

# With containerd, CNI config can also be in:
# /var/lib/rancher/k3s/agent/etc/cni/net.d/ (k3s)
```

The file naming convention in `/etc/cni/net.d/` matters — kubelet uses the file with the lowest alphanumeric name. If you have multiple files, the `10-` prefix wins over `20-`. Misconfigured CNI configs are a common cause of pods stuck in `ContainerCreating`.

---

## Step 7 — Inspect the CNI Binaries

```bash
# CNI binaries live in /opt/cni/bin/
ls -la /opt/cni/bin/

# With Calico installed, you'll see:
# calico         — main Calico CNI binary
# calico-ipam    — IP address management
# bandwidth      — traffic shaping
# portmap        — port mapping (HostPort support)
# loopback       — loopback interface setup
# tuning         — sysctl tuning

# Standard CNI reference binaries (always present):
# bridge, host-local, ipvlan, macvlan, ptp, vlan, dhcp

# Check CNI binary versions
/opt/cni/bin/loopback --version 2>/dev/null || echo "loopback has no --version"

# The kubelet flag points to these directories
ps aux | grep kubelet | grep cni
# Look for --cni-conf-dir and --cni-bin-dir flags
```

If a required CNI binary is missing from `/opt/cni/bin/`, pods will fail with `failed to find plugin "calico" in path [/opt/cni/bin]`. Copying the binary to this directory fixes it without restarting anything.

---

## Step 8 — Trace a Pod Network Setup

```bash
# When a pod is created, kubelet calls the CNI plugin:
# 1. kubelet creates a network namespace for the pod
# 2. kubelet calls: /opt/cni/bin/<plugin> with the config from /etc/cni/net.d/
# 3. CNI plugin sets up the veth pair, assigns IP, configures routing
# 4. Pod gets its IP address

# Watch CNI in action by creating a pod and watching interfaces
ip link show | grep -c veth  # Count existing veth pairs

kubectl run test-cni --image=nginx
sleep 5

ip link show | grep -c veth  # Count should increase by 1

# Find the veth pair for the new pod
POD_IP=$(kubectl get pod test-cni -o jsonpath='{.status.podIP}')
echo "Pod IP: $POD_IP"

# Find the host veth that connects to this pod
ip route | grep $POD_IP

# View all network namespaces
ip netns list

kubectl delete pod test-cni
```

Each pod gets its own network namespace connected to the host via a veth pair. The CNI plugin creates the veth pair, puts one end in the pod's namespace, and configures routing on the host side.

---

## Step 9 — Inspect CSI Drivers

```bash
# CSI (Container Storage Interface) drivers are registered as CSIDriver resources
kubectl get csidrivers

# In a fresh cluster without a CSI driver installed, this may be empty
# On cloud providers (EKS, GKE, AKS), you'll see drivers like:
# ebs.csi.aws.com
# pd.csi.storage.gke.io
# disk.csi.azure.com

# After installing a CSI driver (e.g., local-path-provisioner):
# kubectl get csidrivers

# View details of a CSI driver
kubectl describe csidriver <driver-name> 2>/dev/null || \
  echo "Install a CSI driver to see details"

# CSI drivers create nodes too (one per node)
kubectl get csinodes

# View volume attachments managed by CSI
kubectl get volumeattachments
```

CSI drivers register themselves via the `CSIDriver` Kubernetes resource. The kubelet communicates with the CSI driver via a gRPC socket to mount/unmount volumes on the node.

---

## Step 10 — Install a Local CSI Driver for Testing

```bash
# Install local-path-provisioner (a simple CSI driver for local storage)
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

# Wait for it to be ready
kubectl rollout status deployment local-path-provisioner \
  -n local-path-storage --timeout=60s

# View the CSI-related resources
kubectl get storageclass
# local-path   rancher.io/local-path   ...

# Create a PVC using the local-path provisioner
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 1Gi
EOF

# Create a pod that uses the PVC
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-pvc-pod
spec:
  containers:
  - name: test
    image: busybox
    command: ["sh", "-c", "echo hello > /data/test.txt && sleep infinity"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: test-pvc
EOF

kubectl wait --for=condition=Ready pod/test-pvc-pod --timeout=60s
kubectl exec test-pvc-pod -- cat /data/test.txt
# hello
```

The local-path-provisioner creates a hostPath PV when a PVC is bound. It's not a true CSI driver but demonstrates dynamic provisioning. Lab 24 covers StorageClasses and dynamic provisioning in detail.

---

## Step 11 — Summary of Extension Interface Locations

```bash
# Quick reference for CKA exam:
echo "
CRI (containerd):
  Socket:      /run/containerd/containerd.sock
  CLI:         crictl (configured via /etc/crictl.yaml)
  Logs:        journalctl -u containerd
  Config:      /etc/containerd/config.toml

CNI:
  Config dir:  /etc/cni/net.d/
  Binaries:    /opt/cni/bin/
  Debug:       ip link, ip route, ip netns

CSI:
  Register:    kubectl get csidrivers
  Nodes:       kubectl get csinodes
  Attachments: kubectl get volumeattachments
  Socket:      /var/lib/kubelet/plugins/<driver>/csi.sock

kubelet:
  Config:      /etc/kubernetes/kubelet.conf
               /var/lib/kubelet/config.yaml
  Static pods: /etc/kubernetes/manifests/
  Logs:        journalctl -u kubelet
"
```

---

## Free online tools
- **Kubernetes Docs — CRI**: https://kubernetes.io/docs/concepts/architecture/cri/
- **Kubernetes Docs — CNI**: https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/
- **Kubernetes Docs — CSI**: https://kubernetes.io/docs/concepts/storage/volumes/#csi
- **killer.sh** — CKA mock exam: https://killer.sh

---

## What you learned
- CRI, CNI, and CSI are three pluggable interfaces that make Kubernetes runtime-agnostic
- `crictl` talks directly to the container runtime, bypassing kubelet — essential when the API server is down
- Configure crictl via `/etc/crictl.yaml` with the correct runtime socket path
- `crictl pods`, `crictl ps`, `crictl logs`, and `crictl images` are the key crictl commands
- CNI config files in `/etc/cni/net.d/` are JSON; the lowest-numbered file is used
- CNI binaries in `/opt/cni/bin/` are executable plugins called by kubelet during pod creation
- Each pod gets its own network namespace connected via a veth pair to the host
- CSI drivers register as `CSIDriver` resources; view with `kubectl get csidrivers`
- `kubectl get csinodes` and `kubectl get volumeattachments` show CSI driver state per node
- Use `journalctl -u containerd` and `journalctl -u kubelet` for runtime-level logs
