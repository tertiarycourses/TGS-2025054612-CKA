# Step 6 — Controller-manager and scheduler

```bash
kubectl -n kube-system logs $(kubectl -n kube-system get pod -l component=kube-controller-manager -o name) | tail
kubectl -n kube-system logs $(kubectl -n kube-system get pod -l component=kube-scheduler -o name) | tail
```

Look for `leaderelection lost` or `connection refused to apiserver`.
