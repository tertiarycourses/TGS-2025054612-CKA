# Step 7 — Cleanup

```bash
kubectl delete ingress demo
kubectl delete secret app1-tls
kubectl delete svc app1 app2
kubectl delete deploy app1 app2
rm tls.key tls.crt
```
