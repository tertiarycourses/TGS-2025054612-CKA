# Step 3 — Join the worker

On **node01**, paste the join command from Step 1, prefixed with `sudo`:

```bash
sudo kubeadm join <CONTROLPLANE_IP>:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

If the token expired (24 h TTL), regenerate it on the control plane:

```bash
kubeadm token create --print-join-command
```
