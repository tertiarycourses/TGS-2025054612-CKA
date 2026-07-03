# Step 5 — Allow from another namespace

```bash
kubectl create ns trusted
kubectl label ns trusted purpose=trusted
kubectl -n trusted run remote --image=nicolaka/netshoot --command -- sleep 3600
kubectl -n trusted wait --for=condition=Ready pod/remote --timeout=60s

kubectl -n netpol patch networkpolicy allow-trusted --type=merge -p '
spec:
  ingress:
  - from:
    - podSelector: { matchLabels: { role: allowed } }
    - namespaceSelector: { matchLabels: { purpose: trusted } }
    ports:
    - { protocol: TCP, port: 80 }'

kubectl -n trusted exec remote -- curl -s -o /dev/null -w "%{http_code}\n" http://server.netpol.svc.cluster.local
```
