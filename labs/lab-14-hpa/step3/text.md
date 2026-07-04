# Step 3 — Create the HPA

```bash
kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=5
kubectl get hpa
```
