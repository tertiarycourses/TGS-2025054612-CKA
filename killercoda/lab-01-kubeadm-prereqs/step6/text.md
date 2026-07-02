# Step 6 — Verify

```bash
kubeadm version
kubectl version --client
sudo systemctl status containerd --no-pager | head
sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock version
```

You should see kubeadm v1.31.x, containerd active, and crictl reporting the runtime version.

The node is now fully prepped and ready for `kubeadm init` in Lab 2.
