# Step 3 — Grant minimal access

```bash
kubectl -n app create role pod-reader --verb=get,list,watch --resource=pods
kubectl -n app create rolebinding worker-reader --role=pod-reader --serviceaccount=app:worker
kubectl -n app exec worker-pod -- kubectl get pods
```
