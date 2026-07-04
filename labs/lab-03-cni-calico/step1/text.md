# Step 1 — Apply the Calico manifest

On the **controlplane**:

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
```

This creates:
- `calico-system` and `calico-apiserver` (Tigera operator may vary by version) — for the manifest above, resources land in `kube-system`.
- A DaemonSet `calico-node` (one pod per node, wires the CNI binary into `/opt/cni/bin`).
- A Deployment `calico-kube-controllers`.
