# Step 3 — Create the Ingress

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: app1.local
    http:
      paths:
      - { path: /, pathType: Prefix, backend: { service: { name: app1, port: { number: 80 } } } }
  - host: app2.local
    http:
      paths:
      - { path: /, pathType: Prefix, backend: { service: { name: app2, port: { number: 80 } } } }
EOF
kubectl get ingress
```
