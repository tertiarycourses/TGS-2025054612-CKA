# Lab 5 — Highly-Available Control Plane

In this lab you study the architecture of a Highly-Available (HA) Kubernetes control plane and reproduce the key configuration pieces. You will not stand up three real control-plane VMs (the free Killercoda playground gives you two nodes), but you will configure the load-balancer front end and run a `kubeadm init` with the `--control-plane-endpoint` flag that an HA cluster requires.

**Lab environment:** [Play with Kubernetes](https://labs.play-with-k8s.com)
---

## Step 1 — HA topology overview

The standard HA layout is "stacked etcd":

```
            VIP / LB :6443
                 │
   ┌─────────────┼─────────────┐
   ▼             ▼             ▼
cp-1          cp-2          cp-3        ← each runs apiserver + etcd member
   │             │             │
   └─────────────┼─────────────┘
                 ▼
              workers
```

The clients (kubectl, kubelets) talk to a **load-balanced virtual IP** that fronts the three apiservers. etcd runs as a 3-node Raft quorum on the same hosts.

---

## Step 2 — Install HAProxy + keepalived for the VIP

On every prospective control-plane node:

```bash
sudo apt update && sudo apt install -y haproxy keepalived
```

`/etc/haproxy/haproxy.cfg` (TCP passthrough for the apiserver):

```
frontend kube-apiserver
    bind *:6443
    mode tcp
    default_backend kube-apiserver

backend kube-apiserver
    mode tcp
    balance roundrobin
    option tcp-check
    server cp-1 10.0.0.11:6443 check
    server cp-2 10.0.0.12:6443 check
    server cp-3 10.0.0.13:6443 check
```

`/etc/keepalived/keepalived.conf` (active/standby VIP `10.0.0.10`):

```
vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 101
    advert_int 1
    authentication { auth_type PASS auth_pass changeme }
    virtual_ipaddress { 10.0.0.10 }
}
```

```bash
sudo systemctl restart haproxy keepalived
ip addr show eth0 | grep 10.0.0.10
```

---

## Step 3 — kubeadm init with control-plane endpoint

On the first control plane:

```bash
sudo kubeadm init \
  --control-plane-endpoint "10.0.0.10:6443" \
  --upload-certs \
  --pod-network-cidr=192.168.0.0/16
```

- `--control-plane-endpoint` bakes the VIP into the generated certs and kubeconfigs.
- `--upload-certs` stores the PKI temporarily in a Secret so other control planes can join without manually copying files.

The output prints **two** join commands — one for additional control planes (`--control-plane --certificate-key ...`) and one for workers.

---

## Step 4 — Join additional control planes (reference)

```bash
sudo kubeadm join 10.0.0.10:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane \
  --certificate-key <key>
```

Each new control plane runs its own apiserver, registers as an etcd member, and starts serving the VIP.

---

## Step 5 — Verify quorum

On any control plane:

```bash
kubectl get pods -n kube-system -l component=etcd
kubectl -n kube-system exec etcd-cp-1 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list
```

You should see three voting etcd members. Losing one keeps the cluster writable; losing two breaks quorum.

---

## What you learned
- The stacked-etcd HA topology and the role of the VIP.
- How HAProxy + keepalived front three apiservers.
- The `--control-plane-endpoint` and `--upload-certs` flags that make HA `kubeadm init` work.
