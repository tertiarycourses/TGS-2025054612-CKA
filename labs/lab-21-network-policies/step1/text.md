# Step 1 — Create a test namespace and pods

```bash
kubectl create ns netpol
kubectl -n netpol run server --image=nginx --labels="app=server"
kubectl -n netpol run client-ok --image=nicolaka/netshoot --labels="role=allowed" --command -- sleep 3600
kubectl -n netpol run client-bad --image=nicolaka/netshoot --labels="role=denied" --command -- sleep 3600
kubectl -n netpol expose pod server --port=80
kubectl -n netpol wait --for=condition=Ready pod --all --timeout=60s
```
