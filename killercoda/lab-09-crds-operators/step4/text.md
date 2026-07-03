# Step 4 — Create a self-signed Issuer + Certificate

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata: { name: selfsigned, namespace: default }
spec: { selfSigned: {} }
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata: { name: test-cert, namespace: default }
spec:
  secretName: test-cert-tls
  duration: 24h
  commonName: example.local
  issuerRef:
    name: selfsigned
    kind: Issuer
EOF
```

```bash
kubectl get certificate
kubectl get secret test-cert-tls
```

Cert-manager's controller saw the `Certificate` object, ran the issuance flow, and created the `test-cert-tls` Secret containing `tls.crt` + `tls.key`. **That** is the operator pattern.
