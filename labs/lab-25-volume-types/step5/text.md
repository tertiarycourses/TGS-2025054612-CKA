# Step 5 — downwardAPI (pod metadata as files)

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: downward-demo
  labels: { tier: web, env: prod }
spec:
  containers:
  - name: app
    image: busybox
    command: ["sh","-c","cat /info/labels /info/name; sleep 3600"]
    volumeMounts: [{ name: info, mountPath: /info }]
  volumes:
  - name: info
    downwardAPI:
      items:
      - path: labels
        fieldRef: { fieldPath: metadata.labels }
      - path: name
        fieldRef: { fieldPath: metadata.name }
EOF
kubectl wait --for=condition=Ready pod/downward-demo --timeout=60s
kubectl logs downward-demo
```
