# Step 6 — Traceroute across nodes (if multi-node)

```bash
kubectl exec client -- traceroute -n $SERVER_IP
```

You'll see one or two hops depending on whether the pods landed on the same node.
