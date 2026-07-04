# Step 4 — DaemonSet (one pod per node)

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata: { name: log-agent, namespace: kube-system }
spec:
  selector: { matchLabels: { app: log-agent } }
  template:
    metadata: { labels: { app: log-agent } }
    spec:
      tolerations:
      - operator: Exists
      containers:
      - name: agent
        image: busybox
        command: ["sh","-c","while true; do echo log; sleep 60; done"]
EOF
kubectl -n kube-system get ds log-agent
kubectl -n kube-system get pods -l app=log-agent -o wide
```

You should see one pod per node (including the control plane, thanks to the `Exists` toleration).
