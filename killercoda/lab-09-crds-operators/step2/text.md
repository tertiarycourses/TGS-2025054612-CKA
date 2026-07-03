# Step 2 — Use the new resource

```bash
kubectl api-resources | grep widgets
cat <<'EOF' | kubectl apply -f -
apiVersion: training.example.com/v1
kind: Widget
metadata:
  name: blue-widget
spec:
  color: blue
  size: 7
EOF
kubectl get widgets
kubectl describe widget blue-widget
```

The CRD gives you storage and validation, but **no controller is reconciling it** — `kubectl get widgets` reads from etcd, nothing else happens. That's the missing operator piece.
