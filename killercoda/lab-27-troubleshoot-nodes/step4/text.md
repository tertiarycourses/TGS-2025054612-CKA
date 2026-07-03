# Step 4 — Cordon and drain

Sometimes you need to take a node out of service safely.

```bash
kubectl cordon node01
kubectl get nodes
kubectl drain node01 --ignore-daemonsets --delete-emptydir-data
```

`cordon` marks unschedulable; `drain` evicts existing pods.

Bring it back:

```bash
kubectl uncordon node01
```
