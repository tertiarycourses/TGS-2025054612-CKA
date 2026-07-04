# Step 5 — Verify quorum

On any control plane:

```bash
kubectl get pods -n kube-system -l component=etcd
kubectl -n kube-system exec etcd-cp-1 -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list
```

You should see three voting etcd members. Losing one keeps the cluster writable; losing two breaks quorum.
