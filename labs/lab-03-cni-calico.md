# Lab 3 — Install Calico CNI, Verify Nodes Ready, Test Cross-Node Pod Ping

A freshly initialized Kubernetes cluster has nodes in `NotReady` state because there is no Container Network Interface (CNI) plugin to provide pod networking. This lab installs Calico as the CNI plugin, watches nodes transition to `Ready`, deploys pods on different nodes, and validates cross-node pod communication with ping. Understanding CNI installation and verification is essential for both cluster setup questions and networking troubleshooting on the CKA exam.

Run on https://killercoda.com/playgrounds/scenario/kubeadm

**Required software (free):**
- kubectl v1.35 (pre-installed from Lab 2)
- curl (pre-installed)
- Calico v3.29 (installed in this lab)

---

## Step 1 — Confirm Nodes are NotReady Before CNI

```bash
# Before CNI: nodes show NotReady
kubectl get nodes -o wide
# NAME           STATUS     ROLES           AGE   VERSION
# controlplane   NotReady   control-plane   5m    v1.35.0
# worker01       NotReady   <none>          3m    v1.35.0

# The coredns pods will be Pending (no network)
kubectl get pods -n kube-system
# coredns pods: Pending — waiting for network

# Describe a node to see the condition
kubectl describe node controlplane | grep -A 10 'Conditions:'
# Ready: False  Reason: KubeletNotReady  Message: container runtime network not ready
```

The `KubeletNotReady` condition with message "container runtime network not ready" confirms CNI is missing. All pods requiring network communication will stay `Pending` until CNI is installed.

---

## Step 2 — Download the Calico Manifests

```bash
# Download Calico operator manifest
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.29.0/manifests/tigera-operator.yaml

# Download the Calico custom resource manifest
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.29.0/manifests/custom-resources.yaml

# Verify downloads
ls -la tigera-operator.yaml custom-resources.yaml
wc -l tigera-operator.yaml custom-resources.yaml
```

Calico uses an operator pattern: the Tigera Operator manages the Calico components. The `custom-resources.yaml` contains the `Installation` custom resource that configures the pod CIDR.

---

## Step 3 — Configure the Pod CIDR in Calico

```bash
# View the default pod CIDR in custom-resources.yaml
grep 'cidr' custom-resources.yaml
# Default is 192.168.0.0/16

# If your kubeadm init used a different pod CIDR, update it:
# sed -i 's|192.168.0.0/16|<YOUR_POD_CIDR>|g' custom-resources.yaml

# For this lab we used 192.168.0.0/16 in kubeadm init — no change needed

# View the full Installation resource
cat custom-resources.yaml
```

The pod CIDR in `custom-resources.yaml` MUST match what you specified with `--pod-network-cidr` during `kubeadm init`. A mismatch causes pod networking failures.

---

## Step 4 — Install the Calico Operator and Custom Resources

```bash
# Install the Tigera Operator (manages Calico components)
kubectl apply -f tigera-operator.yaml

# Wait for the operator to be ready
kubectl rollout status deployment tigera-operator -n tigera-operator --timeout=120s

# Install Calico via the custom Installation resource
kubectl apply -f custom-resources.yaml

# Watch Calico components come up (takes 1-3 minutes)
watch kubectl get pods -n calico-system
# You should see: calico-node (DaemonSet), calico-kube-controllers, calico-typha
```

The operator creates the `calico-system` namespace and deploys calico-node (as a DaemonSet on every node), calico-kube-controllers, and calico-typha. Wait for all to reach `Running` state.

---

## Step 5 — Watch Nodes Transition to Ready

```bash
# Watch nodes — they will become Ready as Calico starts
kubectl get nodes -w
# NAME           STATUS   ROLES           AGE   VERSION
# controlplane   Ready    control-plane   8m    v1.35.0
# worker01       Ready    <none>          6m    v1.35.0

# Also watch the system pods come up
kubectl get pods -n kube-system -w

# Verify calico-node is Running on all nodes
kubectl get pods -n calico-system -o wide
# Each node should have one calico-node pod

# Check kube-proxy is running (installed by kubeadm)
kubectl get pods -n kube-system -l k8s-app=kube-proxy
```

Nodes transition to `Ready` when the kubelet can reach the CNI plugin and create pod network interfaces. The coredns pods also become `Running` once networking is available.

---

## Step 6 — Verify coredns is Running

```bash
# CoreDNS should now be running
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Test DNS resolution from inside a pod
kubectl run dns-test --image=busybox:1.28 --restart=Never -- \
  nslookup kubernetes.default.svc.cluster.local

kubectl logs dns-test
# Expected output:
# Server:    10.96.0.10
# Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local
# Name:      kubernetes.default.svc.cluster.local
# Address 1: 10.96.0.1

kubectl delete pod dns-test
```

CoreDNS provides in-cluster DNS. If coredns pods are not running after CNI installation, DNS lookups from pods will fail with `SERVFAIL`, causing service discovery to break.

---

## Step 7 — Deploy Test Pods on Different Nodes

```bash
# Deploy a pod pinned to the control plane node
kubectl run pod-cp \
  --image=nicolaka/netshoot \
  --overrides='{"spec":{"nodeName":"controlplane"}}' \
  -- sleep infinity

# Deploy a pod pinned to the worker node
kubectl run pod-worker \
  --image=nicolaka/netshoot \
  --overrides='{"spec":{"nodeName":"worker01"}}' \
  -- sleep infinity

# Wait for both pods to be Running
kubectl get pods -o wide
# Verify they are on different nodes and have IPs in 192.168.x.x range

POD_CP_IP=$(kubectl get pod pod-cp -o jsonpath='{.status.podIP}')
POD_WORKER_IP=$(kubectl get pod pod-worker -o jsonpath='{.status.podIP}')
echo "Control plane pod IP: $POD_CP_IP"
echo "Worker pod IP:        $POD_WORKER_IP"
```

`nicolaka/netshoot` is a network troubleshooting container image with ping, curl, nslookup, traceroute, and many other tools pre-installed. It is commonly used in CKA troubleshooting scenarios.

---

## Step 8 — Test Cross-Node Pod Ping

```bash
# Ping from control-plane pod to worker pod
kubectl exec pod-cp -- ping -c 4 $POD_WORKER_IP

# Expected output:
# PING 192.168.x.x: 56 data bytes
# 64 bytes from 192.168.x.x: seq=0 ttl=62 time=0.5 ms
# ...
# 4 packets transmitted, 4 packets received, 0% packet loss

# Ping from worker pod to control-plane pod
kubectl exec pod-worker -- ping -c 4 $POD_CP_IP

# Verify the Kubernetes flat network (no NAT between pods on different nodes)
kubectl exec pod-cp -- traceroute $POD_WORKER_IP
```

Kubernetes requires a flat pod network where every pod can communicate with every other pod without NAT. Calico achieves this using BGP routing or IP-in-IP tunneling between nodes. A failed cross-node ping indicates a CNI misconfiguration.

---

## Step 9 — Inspect Calico Network Configuration

```bash
# View the Calico node configuration
kubectl get felixconfigurations.crd.projectcalico.org -o yaml

# View IPPools (pod CIDR allocation)
kubectl get ippools.crd.projectcalico.org -o yaml
# Shows: cidr: 192.168.0.0/16, ipipMode, natOutgoing

# Check the CNI config file on the host
cat /etc/cni/net.d/10-calico.conflist

# List CNI binaries installed
ls /opt/cni/bin/
# calico, calico-ipam, bandwidth, portmap, etc.

# View network interfaces created by Calico
ip addr show | grep -E 'cali|tunl'
ip route | grep -E 'cali|192.168'
```

The CNI config file in `/etc/cni/net.d/` is read by kubelet to find which CNI plugin to invoke when creating pods. The CNI binaries in `/opt/cni/bin/` are the executables. Both directories are critical for CNI troubleshooting.

---

## Step 10 — Test Pod-to-Service Connectivity

```bash
# Create a service and test connectivity from a pod
kubectl create deployment web --image=nginx --replicas=2
kubectl expose deployment web --port=80

# Get the ClusterIP
kubectl get svc web
WEB_IP=$(kubectl get svc web -o jsonpath='{.spec.clusterIP}')
echo "Web service ClusterIP: $WEB_IP"

# Curl the service from the test pod
kubectl exec pod-cp -- curl -s http://$WEB_IP | grep -i '<title>'
# Expected: <title>Welcome to nginx!</title>

# Test DNS-based service discovery
kubectl exec pod-cp -- curl -s http://web.default.svc.cluster.local | grep -i '<title>'
```

Pod-to-service connectivity through ClusterIP relies on kube-proxy iptables rules. Successful curl to the service DNS name confirms both CNI (pod network) and CoreDNS (service discovery) are working correctly.

---

## Step 11 — Clean Up Test Resources

```bash
# Remove test pods and deployment
kubectl delete pod pod-cp pod-worker
kubectl delete deployment web
kubectl delete svc web

# Final cluster health check
kubectl get nodes
kubectl get pods -n kube-system
kubectl get pods -n calico-system

# All nodes should be Ready, all system pods Running
```

After cleanup, verify all nodes remain in `Ready` state and no system pods are in `CrashLoopBackOff` or `Error` state before proceeding to Lab 4 (cluster upgrade).

---

## Free online tools
- **Kubernetes Docs — CNI**: https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/
- **Calico documentation**: https://docs.tigera.io/calico/latest/getting-started/kubernetes/
- **killer.sh** — CKA mock exam: https://killer.sh
- **Killercoda kubeadm playground**: https://killercoda.com/playgrounds/scenario/kubeadm
- **netshoot image** — network troubleshooting: https://github.com/nicolaka/netshoot

---

## What you learned
- Nodes stay `NotReady` until a CNI plugin provides pod networking; coredns stays `Pending`
- Calico uses the Tigera Operator pattern: install operator first, then apply `Installation` custom resource
- The pod CIDR in Calico's `custom-resources.yaml` must match `--pod-network-cidr` from `kubeadm init`
- CNI config files live in `/etc/cni/net.d/` and CNI binaries live in `/opt/cni/bin/`
- Kubernetes requires a flat pod network — cross-node pod-to-pod communication without NAT
- `nicolaka/netshoot` is the go-to debug image for network troubleshooting in Kubernetes
- CoreDNS becomes functional once CNI is installed, enabling service discovery via DNS
- `ip route` on a node shows Calico routing entries for pod CIDRs on remote nodes
- Cross-node ping failure after CNI install indicates tunnel or BGP configuration issues
