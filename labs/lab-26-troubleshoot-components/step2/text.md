# Step 2 — Break the API server

```bash
sudo sed -i 's|--secure-port=6443|--secure-port=6444|' /etc/kubernetes/manifests/kube-apiserver.yaml
```

Within ~20 s the kubelet re-creates the pod with the bad port.

```bash
kubectl get nodes
# error: dial tcp 127.0.0.1:6443: connect: connection refused
```
