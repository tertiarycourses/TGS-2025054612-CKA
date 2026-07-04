# Step 1 — Single-container logs

```bash
kubectl create deployment chatty --image=busybox \
  -- /bin/sh -c "i=0; while true; do echo line-\$i; i=\$((i+1)); sleep 1; done"
kubectl wait --for=condition=Available deploy/chatty --timeout=60s
POD=$(kubectl get pod -l app=chatty -o name | head -1)
kubectl logs $POD --tail=10
kubectl logs $POD -f &
sleep 5
kill %1
```
