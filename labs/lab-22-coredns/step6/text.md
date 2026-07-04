# Step 6 — Customize the Corefile

Add a stub zone for `example.com`:

```bash
kubectl -n kube-system edit configmap coredns
```

Add inside `Corefile:` next to `.:53 {`:

```
example.com:53 {
    forward . 8.8.8.8
}
```

Restart CoreDNS:

```bash
kubectl -n kube-system rollout restart deploy coredns
```

Query:

```bash
kubectl exec dnsdebug -- dig +short www.example.com
```
