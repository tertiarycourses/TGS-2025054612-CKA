# Step 4 — Trace a pod through all three interfaces

```bash
kubectl run demo --image=nginx
kubectl wait --for=condition=Ready pod/demo --timeout=60s

# CRI side
sudo crictl ps | grep demo

# CNI side
kubectl get pod demo -o jsonpath='{.status.podIP}{"\n"}'

# CSI side (no storage attached, but show the node's allocatable)
kubectl describe csinode $(hostname)
```

Tear down:

```bash
kubectl delete pod demo
```
