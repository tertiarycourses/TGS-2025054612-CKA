# Step 3 — NodePort

```bash
kubectl expose deploy web --port=80 --type=NodePort --name=web-nodeport
kubectl get svc web-nodeport
PORT=$(kubectl get svc web-nodeport -o jsonpath='{.spec.ports[0].nodePort}')
curl -s http://localhost:$PORT | head -5
```

NodePort opens the same high-numbered port on every node and forwards to the ClusterIP.
