# Lab 5 — HA Control Plane: HAProxy + Keepalived VIP, --control-plane-endpoint, --upload-certs

A production Kubernetes cluster requires multiple control plane nodes so that losing one node does not take down the entire cluster. This lab sets up a highly available (HA) control plane topology using HAProxy as a load balancer and Keepalived to provide a floating Virtual IP (VIP). You will initialize the first control plane with `--control-plane-endpoint` pointing to the VIP and `--upload-certs` to securely share certificates, then join additional control plane nodes. This topology is tested in the CKA exam when questions ask about cluster resilience and etcd quorum.

Run on https://killercoda.com/playgrounds/scenario/kubeadm

**Required software (free):**
- haproxy (install command below)
- keepalived (install command below)
- kubeadm v1.35 (from Lab 1)

---

## Step 1 — Understand HA Topology Options

```bash
# Two supported HA topologies in Kubernetes:

# 1. Stacked etcd (default): etcd runs ON each control plane node
#    - Simpler setup, fewer machines
#    - Risk: losing a control plane node also loses an etcd member
#    - Requires minimum 3 control plane nodes for quorum

# 2. External etcd: etcd runs on SEPARATE nodes
#    - More resilient, more complex
#    - Requires dedicated etcd cluster (3 or 5 nodes)
#    - Control plane nodes can fail independently of etcd

# This lab uses stacked etcd (most common in CKA exam)

# Typical HA cluster layout:
echo "
Node Layout:
  Load Balancer VIP:  192.168.1.100 (floating, managed by keepalived)
  control-plane-01:   192.168.1.101
  control-plane-02:   192.168.1.102
  control-plane-03:   192.168.1.103
  worker-01:          192.168.1.104
  worker-02:          192.168.1.105
"
```

etcd uses the Raft consensus algorithm and requires a quorum of `(n/2)+1` members. With 3 control plane nodes, you can lose 1 and still maintain quorum. With 5 nodes, you can lose 2.

---

## Step 2 — Install HAProxy on the Load Balancer Node

```bash
# Run on the LOAD BALANCER node (or a control plane node in this lab)
apt-get update && apt-get install -y haproxy

# Verify installation
haproxy -v
# HAProxy version x.x.x

# Back up the default config
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.backup
```

HAProxy acts as a TCP load balancer for the Kubernetes API server (port 6443). All kubectl commands and kubeadm join operations talk to the VIP, which HAProxy forwards to an available control plane node.

---

## Step 3 — Configure HAProxy for the API Server

```bash
# Write the HAProxy configuration
cat <<'EOF' > /etc/haproxy/haproxy.cfg
global
    log /dev/log local0
    log /dev/log local1 notice
    daemon

defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    timeout connect 5000ms
    timeout client  50000ms
    timeout server  50000ms

frontend kubernetes-apiserver
    bind *:6443
    default_backend kubernetes-apiserver

backend kubernetes-apiserver
    option  tcp-check
    balance roundrobin
    server control-plane-01 192.168.1.101:6443 check fall 3 rise 2
    server control-plane-02 192.168.1.102:6443 check fall 3 rise 2
    server control-plane-03 192.168.1.103:6443 check fall 3 rise 2
EOF

# Validate the configuration
haproxy -c -f /etc/haproxy/haproxy.cfg

# Start and enable HAProxy
systemctl restart haproxy
systemctl enable haproxy
systemctl status haproxy --no-pager
```

HAProxy uses `mode tcp` (not `mode http`) because HTTPS/TLS is terminated at the API server, not at the load balancer. The `check` parameter enables health checking of backend API servers.

---

## Step 4 — Install and Configure Keepalived

```bash
# Install keepalived on all control plane nodes (and optionally the LB node)
apt-get install -y keepalived

# Determine the network interface name
ip addr show | grep -E '^[0-9]+:' | awk '{print $2}' | tr -d ':'
# Common names: eth0, ens3, enp0s3

INTERFACE="eth0"  # Replace with your interface name
VIP="192.168.1.100"
```

Keepalived uses VRRP (Virtual Router Redundancy Protocol) to provide a floating VIP. One node is MASTER (holds the VIP) and others are BACKUP. If the MASTER fails, BACKUP takes over the VIP within seconds.

---

## Step 5 — Configure Keepalived on the Primary Control Plane

```bash
# Create the keepalived configuration on control-plane-01 (MASTER)
cat <<EOF > /etc/keepalived/keepalived.conf
! Configuration File for keepalived

global_defs {
   router_id LVS_DEVEL
}

vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance VI_1 {
    state MASTER
    interface $INTERFACE
    virtual_router_id 51
    priority 101
    authentication {
        auth_type PASS
        auth_pass K8sSuperSecret
    }
    virtual_ipaddress {
        $VIP
    }
    track_script {
        check_apiserver
    }
}
EOF

# Create the health check script
cat <<'EOF' > /etc/keepalived/check_apiserver.sh
#!/bin/sh
errorExit() {
    echo "*** $*" 1>&2
    exit 1
}

curl --silent --max-time 2 --insecure \
  https://localhost:6443/healthz -o /dev/null || \
  errorExit "Error: GET https://localhost:6443/healthz failed"
exit 0
EOF

chmod +x /etc/keepalived/check_apiserver.sh

systemctl restart keepalived
systemctl enable keepalived
```

The health check script pings `/healthz` on the local API server. If the API server is down, keepalived reduces the priority, causing another node to win the VIP election.

---

## Step 6 — Configure Keepalived on Secondary Control Plane Nodes

```bash
# Run on control-plane-02 and control-plane-03 (BACKUP)
# Change: state MASTER → state BACKUP, priority 101 → 100 or 99

cat <<EOF > /etc/keepalived/keepalived.conf
! Configuration File for keepalived

global_defs {
   router_id LVS_DEVEL
}

vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance VI_1 {
    state BACKUP
    interface $INTERFACE
    virtual_router_id 51
    priority 100
    authentication {
        auth_type PASS
        auth_pass K8sSuperSecret
    }
    virtual_ipaddress {
        $VIP
    }
    track_script {
        check_apiserver
    }
}
EOF

# Copy the health check script from primary or recreate it
# Then restart keepalived
systemctl restart keepalived
systemctl enable keepalived

# Verify the VIP is on the primary node
ip addr show | grep $VIP
```

Use the same `virtual_router_id` (51) and `auth_pass` on all keepalived nodes. Lower priority nodes become BACKUP and only claim the VIP if higher priority nodes fail.

---

## Step 7 — Initialize the First Control Plane with --control-plane-endpoint

```bash
# Run on CONTROL PLANE NODE 01

# CRITICAL: --control-plane-endpoint points to the VIP (load balancer address)
# CRITICAL: --upload-certs uploads certs to kubeadm's Secret for other CP nodes to download

kubeadm init \
  --kubernetes-version=v1.35.0 \
  --control-plane-endpoint="192.168.1.100:6443" \
  --pod-network-cidr=192.168.0.0/16 \
  --service-cidr=10.96.0.0/12 \
  --upload-certs

# SAVE THE OUTPUT — it contains:
# 1. Worker join command (--token, --discovery-token-ca-cert-hash)
# 2. Control plane join command (adds --control-plane --certificate-key)

# Set up kubeconfig
mkdir -p $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

`--control-plane-endpoint` sets the external endpoint in all generated certificates and kubeconfigs. ALL nodes and clients should use this VIP address. `--upload-certs` stores encrypted certs in a kubeadm Secret so additional control plane nodes can download them.

---

## Step 8 — Join Additional Control Plane Nodes

```bash
# Run on CONTROL PLANE NODE 02 (and 03)
# Use the control-plane join command from kubeadm init output

# The command looks like:
kubeadm join 192.168.1.100:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane \
  --certificate-key <cert-key>

# The --control-plane flag makes this node a control plane node
# The --certificate-key downloads certs uploaded by --upload-certs

# After joining, set up kubeconfig on the new control plane node
mkdir -p $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# From control-plane-01, verify all control plane nodes joined
kubectl get nodes
```

The `--certificate-key` is valid for only 2 hours after `kubeadm init`. If it expires, run `kubeadm init phase upload-certs --upload-certs` on the first control plane to generate a new key.

---

## Step 9 — Verify HA etcd Cluster

```bash
# Check etcd member list (all 3 control plane nodes should appear)
kubectl -n kube-system exec -it etcd-control-plane-01 -- \
  etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list

# Expected output:
# <id>, started, control-plane-01, https://192.168.1.101:2380, https://192.168.1.101:2379
# <id>, started, control-plane-02, https://192.168.1.102:2380, https://192.168.1.102:2379
# <id>, started, control-plane-03, https://192.168.1.103:2380, https://192.168.1.103:2379

# Check etcd endpoint health across all members
kubectl -n kube-system exec -it etcd-control-plane-01 -- \
  etcdctl \
  --endpoints=https://192.168.1.101:2379,https://192.168.1.102:2379,https://192.168.1.103:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health
```

All three etcd members must show `healthy`. Etcd requires majority quorum — with 3 members, losing 1 is tolerated; losing 2 causes cluster write failures.

---

## Step 10 — Test VIP Failover

```bash
# Verify the VIP is currently on control-plane-01
ip addr show dev $INTERFACE | grep $VIP

# Stop the API server on control-plane-01 to simulate failure
# (Move the static pod manifest out of the watched directory)
mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/

# Wait for keepalived to detect failure (up to 30 seconds)
sleep 30

# Check which node now holds the VIP
# On all control plane nodes:
ip addr show | grep $VIP

# The VIP should now be on control-plane-02

# Test kubectl still works (through VIP → control-plane-02)
kubectl get nodes

# Restore the API server on control-plane-01
mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
```

After restoration, the API server on control-plane-01 recovers, keepalived detects it, and the VIP may migrate back (depending on priority settings). This demonstrates true high availability.

---

## Step 11 — Install CNI and Join Workers

```bash
# Install Calico (same as Lab 3)
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.0/manifests/tigera-operator.yaml
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.0/manifests/custom-resources.yaml

# Wait for Calico
kubectl rollout status daemonset calico-node -n calico-system --timeout=120s

# Join worker nodes using the worker join command from kubeadm init
kubeadm join 192.168.1.100:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>

# Verify all nodes
kubectl get nodes -o wide
```

Workers join via the VIP address. If the primary control plane fails, workers can reconnect through the VIP to any other healthy control plane node.

---

## Free online tools
- **Kubernetes Docs — HA topology**: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/
- **Kubernetes Docs — HA with kubeadm**: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/
- **killer.sh** — CKA mock exam: https://killer.sh
- **Killercoda kubeadm playground**: https://killercoda.com/playgrounds/scenario/kubeadm

---

## What you learned
- Stacked etcd HA requires minimum 3 control plane nodes for quorum (`(n/2)+1`)
- HAProxy uses `mode tcp` to forward API server traffic to backend control plane nodes
- Keepalived provides a floating VIP using VRRP; MASTER holds the VIP, BACKUP takes over on failure
- `--control-plane-endpoint` must point to the VIP address and is baked into all certs/kubeconfigs
- `--upload-certs` stores encrypted certificates in a Kubernetes Secret for additional CP node joins
- The `--certificate-key` from `--upload-certs` expires after 2 hours; regenerate with `kubeadm init phase upload-certs --upload-certs`
- `kubeadm join --control-plane --certificate-key` joins additional control plane nodes
- etcd member list shows all CP nodes; all members must show `healthy` for cluster stability
- VIP failover takes seconds; kubectl continues working through the VIP during control plane failures
- Workers join using the VIP address so they automatically reconnect to surviving CP nodes
