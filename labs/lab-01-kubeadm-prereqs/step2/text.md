# Step 2 — Set required sysctls

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system
```

`ip_forward=1` is mandatory: pods on different nodes route through the host.

Verify:
```bash
sysctl net.ipv4.ip_forward
```

You should see `net.ipv4.ip_forward = 1`.
