# Step 5 — Use a strategic-merge patch

Replace the JSON6902 patch in `dev/kustomization.yaml` with a strategic patch:

```yaml
patches:
  - path: replica-patch.yaml
```

And `kustom/overlays/dev/replica-patch.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata: { name: web }
spec:
  replicas: 2
```

Re-apply with `kubectl apply -k kustom/overlays/dev` and watch the rollout.
