# Step 5 — SRV records

```bash
kubectl exec dnsdebug -- dig SRV _http._tcp.web.default.svc.cluster.local +short
```

The SRV record exposes the port number along with the target host — used by StatefulSet clients to discover peers.
