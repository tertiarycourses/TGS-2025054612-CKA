# Step 2 — Run a query pod

```bash
kubectl run dnsdebug --image=nicolaka/netshoot --command -- sleep 3600
kubectl wait --for=condition=Ready pod/dnsdebug --timeout=60s
kubectl exec dnsdebug -- cat /etc/resolv.conf
```

`nameserver` is the kube-dns ClusterIP; `search` lists the namespace search domains.
