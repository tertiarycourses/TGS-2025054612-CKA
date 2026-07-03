# Step 2 — Set up your kubeconfig

Still on **controlplane**:

```bash
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl get nodes
```

The control plane will show `NotReady` — that's expected until a CNI is installed (Lab 3).
