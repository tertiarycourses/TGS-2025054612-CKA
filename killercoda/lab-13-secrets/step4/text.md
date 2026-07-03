# Step 4 — TLS Secret

```bash
openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
  -keyout tls.key -out tls.crt -subj "/CN=demo.local"
kubectl create secret tls demo-tls --cert=tls.crt --key=tls.key
kubectl get secret demo-tls -o yaml | head
```

TLS Secrets are used by Ingress, Gateway API, and webhook servers (Lab 19, 20).
