# Step 2 — Previous instance after a crash

```bash
kubectl run crashy --image=busybox -- /bin/sh -c "echo running; sleep 5; exit 1"
sleep 30
kubectl get pod crashy
kubectl logs crashy --previous
```

`--previous` (or `-p`) reads the last terminated container's log — invaluable when a CrashLoop hides the actual cause.
