# Step 3 — Multi-container pod

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: { name: multi }
spec:
  containers:
  - name: writer
    image: busybox
    command: ["sh","-c","i=0;while true;do echo writer-$i;i=$((i+1));sleep 1;done"]
  - name: reader
    image: busybox
    command: ["sh","-c","i=0;while true;do echo reader-$i;i=$((i+1));sleep 2;done"]
EOF
kubectl wait --for=condition=Ready pod/multi --timeout=60s

kubectl logs multi              # error: needs -c
kubectl logs multi -c writer --tail=5
kubectl logs multi -c reader --tail=5
kubectl logs multi --all-containers --prefix --tail=10
```
