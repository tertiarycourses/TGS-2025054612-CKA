# Step 2 — Fault 1: selector mismatch

```bash
kubectl patch svc web --type=merge -p '{"spec":{"selector":{"app":"wrong"}}}'
kubectl exec probe -- curl -s --max-time 3 http://web || echo TIMEOUT
kubectl get endpoints web
```

`ENDPOINTS` is empty. The selector no longer matches any pod.

Fix:

```bash
kubectl patch svc web --type=merge -p '{"spec":{"selector":{"app":"web"}}}'
kubectl get endpoints web
```
