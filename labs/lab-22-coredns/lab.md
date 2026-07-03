# Lab 22 — CoreDNS

CoreDNS is the default in-cluster DNS server. Every pod gets `/etc/resolv.conf` pointing to its ClusterIP. In this lab you inspect CoreDNS, query different record types, and customize the Corefile.

**Lab environment:** [KillerCoda](https://killercoda.com/tertiary-labs-cka/course/killercoda/lab-22-coredns)
---

## Step 1 — Find the CoreDNS Service

```bash
kubectl -n kube-system get svc kube-dns
kubectl -n kube-system get pods -l k8s-app=kube-dns
kubectl -n kube-system get configmap coredns -o yaml
```

`kube-dns` is the Service name (legacy) even though the pods are CoreDNS.

---

## Step 2 — Run a query pod

```bash
kubectl run dnsdebug --image=nicolaka/netshoot --command -- sleep 3600
kubectl wait --for=condition=Ready pod/dnsdebug --timeout=60s
kubectl exec dnsdebug -- cat /etc/resolv.conf
```

`nameserver` is the kube-dns ClusterIP; `search` lists the namespace search domains.

---

## Step 3 — Query Service records

```bash
kubectl create deployment web --image=nginx
kubectl expose deploy web --port=80
kubectl exec dnsdebug -- dig +short web.default.svc.cluster.local
kubectl exec dnsdebug -- dig +short web   # short name via search list
```

---

## Step 4 — Pod records (headless services)

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata: { name: web-h }
spec:
  clusterIP: None
  selector: { app: web }
  ports: [{ port: 80 }]
EOF
kubectl exec dnsdebug -- dig +short web-h.default.svc.cluster.local
```

A headless Service returns the **pod IPs** directly — no virtual ClusterIP.

---

## Step 5 — SRV records

```bash
kubectl exec dnsdebug -- dig SRV _http._tcp.web.default.svc.cluster.local +short
```

The SRV record exposes the port number along with the target host — used by StatefulSet clients to discover peers.

---

## Step 6 — Customize the Corefile

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

---

## Step 7 — Cleanup

```bash
kubectl delete pod dnsdebug
kubectl delete svc web web-h
kubectl delete deploy web
```

(Revert the Corefile change if you plan to do more labs.)

---

## What you learned
- `<svc>.<ns>.svc.<cluster-domain>` is the canonical Service FQDN.
- Headless Services return pod IPs; SRV records expose ports.
- The Corefile in `kube-system/coredns` ConfigMap controls all DNS behaviour.
