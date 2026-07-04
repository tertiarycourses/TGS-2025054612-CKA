# Step 2 — Ping by pod IP

```bash
SERVER_IP=$(kubectl get pod server -o jsonpath='{.status.podIP}')
kubectl exec client -- ping -c 3 $SERVER_IP
```

No SNAT, no port mapping — the pod sees its own IP.
