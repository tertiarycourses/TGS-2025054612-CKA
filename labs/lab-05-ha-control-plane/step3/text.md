# Step 3 — kubeadm init with control-plane endpoint

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
