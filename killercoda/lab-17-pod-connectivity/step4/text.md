# Step 4 — DNS-based discovery

Expose `server` as a Service:

```bash
kubectl expose pod server --port=80
kubectl exec client -- nslookup server
kubectl exec client -- curl -s -o /dev/null -w "%{http_code}\n" http://server
```

The Service name `server` resolves to a virtual ClusterIP — covered in Lab 18.
