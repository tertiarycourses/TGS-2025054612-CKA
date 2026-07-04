# Step 2 — nodeSelector

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: ssd-pod }
spec:
  nodeSelector: { disktype: ssd }
  containers:
  - { name: app, image: nginx }
EOF
kubectl get pod ssd-pod -o wide
```

The pod is forced onto the labelled node.
