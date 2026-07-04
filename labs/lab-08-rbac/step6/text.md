# Step 6 — ClusterRole and ClusterRoleBinding

Some permissions are cluster-scoped (nodes, persistentvolumes). Create a read-only cluster role for nodes:

```bash
kubectl create clusterrole node-reader --verb=get,list,watch --resource=nodes
kubectl create clusterrolebinding viewer-nodes \
  --clusterrole=node-reader \
  --serviceaccount=rbac-demo:viewer
kubectl -n rbac-demo exec viewer-pod -- kubectl get nodes
```
