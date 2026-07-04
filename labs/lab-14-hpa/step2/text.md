# Step 2 — Deploy a CPU-bound workload

```bash
kubectl create deployment php-apache --image=registry.k8s.io/hpa-example
kubectl set resources deploy/php-apache --requests=cpu=100m --limits=cpu=500m
kubectl expose deployment php-apache --port=80
kubectl rollout status deploy/php-apache
```
