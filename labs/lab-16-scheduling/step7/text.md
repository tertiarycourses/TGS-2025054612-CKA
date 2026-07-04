# Step 7 — Cleanup

```bash
kubectl delete pod ssd-pod affinity-pod sized tolerant notol --ignore-not-found
kubectl delete deploy spread
kubectl label node $NODE disktype- tier-
```
