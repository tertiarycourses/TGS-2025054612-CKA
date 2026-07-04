# Step 5 — Docker-registry Secret (private image pull)

```bash
kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=demo \
  --docker-password=demo123 \
  --docker-email=demo@example.com
```

Reference from a pod:

```yaml
spec:
  imagePullSecrets:
  - name: regcred
```
