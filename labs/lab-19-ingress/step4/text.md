# Step 4 — Test with Host header

```bash
NODEPORT=$(kubectl -n ingress-nginx get svc ingress-nginx-controller \
  -o jsonpath='{.spec.ports[?(@.port==80)].nodePort}')
curl -s -H "Host: app1.local" http://localhost:$NODEPORT
curl -s -H "Host: app2.local" http://localhost:$NODEPORT
```

You should see "hello from app1" and "hello from app2".
