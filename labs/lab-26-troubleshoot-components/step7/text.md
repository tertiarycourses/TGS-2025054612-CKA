# Step 7 — Cheat sheet

| Symptom                              | Look at                                                      |
|--------------------------------------|--------------------------------------------------------------|
| `kubectl` hangs / `connection refused`| `/var/log/pods/kube-system_kube-apiserver-*`, `crictl logs` |
| Nodes stuck `NotReady`               | `journalctl -u kubelet`, `journalctl -u containerd`          |
| Pods stuck `Pending`                 | kube-scheduler logs                                          |
| New ReplicaSet not creating pods     | kube-controller-manager logs                                 |
| Persistent data missing / inconsistent | etcd logs + `etcdctl endpoint status --write-out=table`     |
