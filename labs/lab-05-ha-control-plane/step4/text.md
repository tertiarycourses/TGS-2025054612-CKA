# Step 4 — Join additional control planes (reference)

```bash
sudo kubeadm join 10.0.0.10:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane \
  --certificate-key <key>
```

Each new control plane runs its own apiserver, registers as an etcd member, and starts serving the VIP.
