# Step 2 — Install HAProxy + keepalived for the VIP

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
