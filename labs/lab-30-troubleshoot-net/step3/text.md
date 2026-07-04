# Step 3 — Fault 2: targetPort mismatch

```bash
kubectl patch svc web --type=merge -p '{"spec":{"ports":[{"port":80,"targetPort":8080}]}}'
kubectl exec probe -- curl -s --max-time 3 http://web || echo FAIL
```

Endpoints are populated, but the wrong port — connection refused.

```bash
kubectl describe svc web | grep -E "Port:|TargetPort"
kubectl exec probe -- curl -s -o /dev/null -w "%{http_code}\n" http://$(kubectl get pod -l app=web -o jsonpath='{.items[0].status.podIP}'):80
```

Fix:

```bash
kubectl patch svc web --type=merge -p '{"spec":{"ports":[{"port":80,"targetPort":80}]}}'
```
