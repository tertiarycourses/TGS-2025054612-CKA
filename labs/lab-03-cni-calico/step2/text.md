# Step 2 — Watch pods come up

```bash
kubectl get pods -n kube-system -w
```

Once `calico-node-*` reports `Running` on both nodes, press Ctrl-C and check:

```bash
kubectl get nodes
```

Both nodes should now be `Ready`.
