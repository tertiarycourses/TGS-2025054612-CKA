# Step 5 — Stop the load and watch scale-down

Ctrl-C the load generator, then:

```bash
kubectl delete pod load
kubectl get hpa -w
```

After ~5 minutes (default stabilization window) the HPA scales back to 1.
