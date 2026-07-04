# Step 3 — Node affinity (soft preference)

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: affinity-pod }
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - { key: tier, operator: In, values: [frontend] }
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 50
        preference:
          matchExpressions:
          - { key: disktype, operator: In, values: [ssd] }
  containers:
  - { name: app, image: nginx }
EOF
kubectl get pod affinity-pod -o wide
```

`required...` is a hard rule, `preferred...` is a soft hint.
