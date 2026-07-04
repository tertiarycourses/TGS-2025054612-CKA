# Step 4 — Wrong scope (common trap)

```bash
kubectl -n app exec worker-pod -- kubectl get nodes
# still Forbidden
```

Nodes are cluster-scoped → need a ClusterRoleBinding, not a RoleBinding:

```bash
kubectl create clusterrole node-reader --verb=get,list,watch --resource=nodes
kubectl create clusterrolebinding worker-nodes --clusterrole=node-reader --serviceaccount=app:worker
kubectl -n app exec worker-pod -- kubectl get nodes
```
