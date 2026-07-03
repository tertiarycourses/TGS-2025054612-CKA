# Step 5 — Disk pressure simulation

```bash
# on node01 — fill /var to >85% (DO NOT do this on a real cluster)
sudo fallocate -l 5G /var/big.fill
```

After ~1 minute:

```bash
kubectl describe node node01 | grep -A2 DiskPressure
kubectl get events --field-selector reason=NodeHasDiskPressure -A
```

Pods may be evicted. Recover:

```bash
sudo rm /var/big.fill
```
