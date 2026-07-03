# Step 3 — Default-deny ingress

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: { name: default-deny, namespace: netpol }
spec:
  podSelector: {}
  policyTypes: [Ingress]
EOF
```

Re-test:

```bash
kubectl -n netpol exec client-ok  -- curl -s --max-time 3 http://server || echo BLOCKED
kubectl -n netpol exec client-bad -- curl -s --max-time 3 http://server || echo BLOCKED
```

Both are now blocked.
