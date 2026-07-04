# Step 6 — Cleanup

```bash
kubectl delete pod sec-env sec-file
kubectl delete secret db-creds demo-tls regcred
rm tls.key tls.crt
```
