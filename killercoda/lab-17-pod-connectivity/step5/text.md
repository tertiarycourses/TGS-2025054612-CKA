# Step 5 — Inspect routing inside the pod

```bash
kubectl exec client -- ip addr
kubectl exec client -- ip route
kubectl exec client -- cat /etc/resolv.conf
```

The default route points to a per-node CNI gateway; `/etc/resolv.conf` points to the CoreDNS ClusterIP.
