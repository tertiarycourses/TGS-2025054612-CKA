# Step 5 — Create an HTTPRoute

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata: { name: echo-route }
spec:
  parentRefs:
  - name: web
  hostnames: ["echo.local"]
  rules:
  - matches:
    - path: { type: PathPrefix, value: / }
    backendRefs:
    - { name: echo, port: 80 }
EOF
kubectl get httproute echo-route -o yaml | grep -A3 status
```
