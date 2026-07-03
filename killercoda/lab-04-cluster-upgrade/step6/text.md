# Step 6 — Repeat on the worker

On **node01**:

```bash
sudo apt-mark unhold kubeadm && sudo apt install -y kubeadm=1.31.0-1.1 && sudo apt-mark hold kubeadm
sudo kubeadm upgrade node
```

Back on **controlplane**:

```bash
kubectl drain node01 --ignore-daemonsets --delete-emptydir-data
```

On **node01**:

```bash
sudo apt-mark unhold kubelet kubectl
sudo apt install -y kubelet=1.31.0-1.1 kubectl=1.31.0-1.1
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload && sudo systemctl restart kubelet
```

On **controlplane**:

```bash
kubectl uncordon node01
kubectl get nodes
```

Both nodes should report the new version.
