# Step 1 — Label your nodes

```bash
kubectl get nodes --show-labels
NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
kubectl label node $NODE disktype=ssd tier=frontend
kubectl get nodes -L disktype,tier
```
