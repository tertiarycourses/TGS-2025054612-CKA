# Step 3 — CSI: list installed drivers

```bash
kubectl get csidrivers
kubectl get csinodes
kubectl get storageclasses
```

On a stock Killercoda cluster you'll usually see `rancher.io/local-path` (Rancher's local-path provisioner). Each CSI driver registers itself with the kubelet via the **CSI plugin socket** at `/var/lib/kubelet/plugins/<driver>/csi.sock`.

```bash
sudo ls /var/lib/kubelet/plugins/ 2>/dev/null
sudo ls /var/lib/kubelet/plugins_registry/ 2>/dev/null
```
