# Step 4 — Inspect the new cluster

Back on **controlplane**:

```bash
kubectl get nodes -o wide
kubectl get pods -n kube-system
```

You should see two nodes (both `NotReady`) and the static control-plane pods running: `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, `etcd`, plus `kube-proxy` and `coredns`. The CoreDNS pods will stay `Pending` until a CNI is up.
