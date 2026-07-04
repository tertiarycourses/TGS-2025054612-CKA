# Step 6 — Egress policy

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: { name: dns-only, namespace: netpol }
spec:
  podSelector: { matchLabels: { role: denied } }
  policyTypes: [Egress]
  egress:
  - to:
    - namespaceSelector: {}
      podSelector: { matchLabels: { k8s-app: kube-dns } }
    ports:
    - { protocol: UDP, port: 53 }
EOF
kubectl -n netpol exec client-bad -- curl -s --max-time 3 http://1.1.1.1 || echo BLOCKED
kubectl -n netpol exec client-bad -- nslookup kubernetes.default
```

`client-bad` can resolve DNS but cannot reach anything else.
