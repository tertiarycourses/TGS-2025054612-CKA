# Step 6 — Taints and tolerations

```bash
kubectl taint node $NODE workload=batch:NoSchedule
kubectl run notol --image=nginx
kubectl get pod notol -o wide   # Pending on a single-node cluster
```

Add a toleration:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: tolerant }
spec:
  tolerations:
  - { key: workload, operator: Equal, value: batch, effect: NoSchedule }
  containers:
  - { name: app, image: nginx }
EOF
kubectl get pod tolerant -o wide
```

Remove the taint:

```bash
kubectl taint node $NODE workload-
```
