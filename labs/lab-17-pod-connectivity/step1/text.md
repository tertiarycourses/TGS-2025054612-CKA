# Step 1 — Launch two debug pods

```bash
kubectl run client --image=nicolaka/netshoot --command -- sleep 3600
kubectl run server --image=nginx
kubectl wait --for=condition=Ready pod/client pod/server --timeout=60s
kubectl get pods -o wide
```

Note each pod's IP and the node it landed on.
