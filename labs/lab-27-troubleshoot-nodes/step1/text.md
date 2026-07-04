# Step 1 — Baseline

```bash
kubectl get nodes
kubectl describe node node01 | grep -E "Conditions|Taints" -A6
```

The five conditions: `Ready`, `MemoryPressure`, `DiskPressure`, `PIDPressure`, `NetworkUnavailable`.
