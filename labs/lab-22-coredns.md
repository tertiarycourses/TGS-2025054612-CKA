# Lab 22 — CoreDNS

CoreDNS is the in-cluster DNS server. Every Pod receives `/etc/resolv.conf` pointing to it. CKA 2026 tests inspecting the Corefile, querying Service and Pod DNS records, headless Service resolution, and customising CoreDNS with stub zones — a common exam question.

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- `kubectl` (pre-installed on Killercoda)
- `nicolaka/netshoot` debug image (pulled automatically)

---

## Step 1 — Inspect CoreDNS

```bash
kubectl -n kube-system get svc kube-dns
kubectl -n kube-system get pods -l k8s-app=kube-dns
kubectl -n kube-system get configmap coredns -o yaml
```

The Service name is `kube-dns` (legacy) even though the Pods run CoreDNS. The ConfigMap `coredns` contains the `Corefile` that controls all DNS behaviour.

---

## Step 2 — Launch a debug Pod and inspect resolv.conf

```bash
kubectl run dnsdebug --image=nicolaka/netshoot --command -- sleep 3600
kubectl wait --for=condition=Ready pod/dnsdebug --timeout=60s
kubectl exec dnsdebug -- cat /etc/resolv.conf
```

Expected:
```
nameserver 10.96.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
ndots:5
```

`ndots:5` means names with fewer than 5 dots check the search list first.

---

## Step 3 — Query Service A records

```bash
kubectl create deployment web --image=nginx
kubectl expose deploy web --port=80
kubectl exec dnsdebug -- dig +short web.default.svc.cluster.local
kubectl exec dnsdebug -- dig +short web
```

The short name `web` resolves via the search list. The FQDN always works.

---

## Step 4 — Headless Service DNS (returns Pod IPs)

```bash
cat > headless.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: web-headless
spec:
  clusterIP: None
  selector:
    app: web
  ports:
  - port: 80
EOF
kubectl apply -f headless.yaml
kubectl exec dnsdebug -- dig +short web-headless.default.svc.cluster.local
```

A headless Service (`clusterIP: None`) returns all Pod IPs directly — no virtual ClusterIP.

---

## Step 5 — SRV records (StatefulSet peer discovery)

```bash
kubectl exec dnsdebug -- dig SRV _http._tcp.web.default.svc.cluster.local +short
```

SRV records expose port information — used by StatefulSet clients to discover peers by ordinal.

---

## Step 6 — Customise CoreDNS with a stub zone

Add a forwarding stub zone for `example.com` to use Google DNS:

```bash
kubectl -n kube-system get configmap coredns -o yaml > coredns-backup.yaml
kubectl -n kube-system edit configmap coredns
```

In the editor, add this block **inside** the `Corefile:` value, next to the existing `.:53 {` block:

```
example.com:53 {
    forward . 8.8.8.8
    cache 30
}
```

Save and restart CoreDNS:

```bash
kubectl -n kube-system rollout restart deploy coredns
kubectl -n kube-system rollout status deploy coredns
kubectl exec dnsdebug -- dig +short www.example.com
```

---

## Step 7 — Restore CoreDNS ConfigMap

```bash
kubectl apply -f coredns-backup.yaml
kubectl -n kube-system rollout restart deploy coredns
```

---

## Step 8 — Clean up

```bash
kubectl delete pod dnsdebug
kubectl delete svc web web-headless
kubectl delete deploy web
```

---

## Free online tools

- **CoreDNS docs**: https://coredns.io/docs/
- **CoreDNS plugins reference**: https://coredns.io/plugins/
- **DNS for Services and Pods**: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/
- **killer.sh** — CKA mock exam: https://killer.sh
- **Kubernetes docs** (allowed in CKA exam): https://kubernetes.io/docs/

---

## What you learned

- Service FQDN: `<svc>.<ns>.svc.cluster.local`.
- Headless Service (`clusterIP: None`) returns Pod IPs; regular ClusterIP returns one virtual IP.
- SRV records provide port + host information for service discovery.
- Stub zones in the Corefile forward specific domains to external resolvers.
- Always restart CoreDNS after editing the ConfigMap: `kubectl rollout restart deploy coredns -n kube-system`.
