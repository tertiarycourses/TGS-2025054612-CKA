# Step 1 — Find the CoreDNS Service

```bash
kubectl -n kube-system get svc kube-dns
kubectl -n kube-system get pods -l k8s-app=kube-dns
kubectl -n kube-system get configmap coredns -o yaml
```

`kube-dns` is the Service name (legacy) even though the pods are CoreDNS.
