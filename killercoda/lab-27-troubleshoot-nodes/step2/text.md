# Step 2 — Stop the kubelet

On **node01**:

```bash
sudo systemctl stop kubelet
```

Back on **controlplane** (wait ~40 s):

```bash
kubectl get nodes
# node01   NotReady
```

`kubectl describe node node01` shows `Kubelet stopped posting node status`.

Fix:

```bash
# on node01
sudo systemctl start kubelet
sudo journalctl -u kubelet -n 20 --no-pager
```
