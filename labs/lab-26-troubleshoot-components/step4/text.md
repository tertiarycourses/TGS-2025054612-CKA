# Step 4 — Fix

```bash
sudo sed -i 's|--secure-port=6444|--secure-port=6443|' /etc/kubernetes/manifests/kube-apiserver.yaml
```

Wait ~30 s for the kubelet to rotate the static pod.

```bash
kubectl get nodes
```
