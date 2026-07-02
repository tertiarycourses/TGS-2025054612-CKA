# Lab 21 — Network Policies

NetworkPolicy is the Kubernetes firewall for pod-to-pod traffic. It requires a CNI that enforces policy (Calico, Cilium, Weave). In this lab you write deny-by-default, then progressively allow traffic.

Use the **Kubernetes playground** (already has Calico): https://killercoda.com/playgrounds/scenario/kubernetes

---

## Step 1 — Create a test namespace and pods

```bash
kubectl create ns netpol
kubectl -n netpol run server --image=nginx --labels="app=server"
kubectl -n netpol run client-ok --image=nicolaka/netshoot --labels="role=allowed" --command -- sleep 3600
kubectl -n netpol run client-bad --image=nicolaka/netshoot --labels="role=denied" --command -- sleep 3600
kubectl -n netpol expose pod server --port=80
kubectl -n netpol wait --for=condition=Ready pod --all --timeout=60s
```

---

## Step 2 — Baseline: everything allowed

```bash
kubectl -n netpol exec client-ok  -- curl -s -o /dev/null -w "%{http_code}\n" http://server
kubectl -n netpol exec client-bad -- curl -s -o /dev/null -w "%{http_code}\n" http://server
```

Both should print `200`.

---

## Step 3 — Default-deny ingress

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: { name: default-deny, namespace: netpol }
spec:
  podSelector: {}
  policyTypes: [Ingress]
EOF
```

Re-test:

```bash
kubectl -n netpol exec client-ok  -- curl -s --max-time 3 http://server || echo BLOCKED
kubectl -n netpol exec client-bad -- curl -s --max-time 3 http://server || echo BLOCKED
```

Both are now blocked.

---

## Step 4 — Allow only the trusted client

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: { name: allow-trusted, namespace: netpol }
spec:
  podSelector: { matchLabels: { app: server } }
  policyTypes: [Ingress]
  ingress:
  - from:
    - podSelector: { matchLabels: { role: allowed } }
    ports:
    - { protocol: TCP, port: 80 }
EOF
```

```bash
kubectl -n netpol exec client-ok  -- curl -s -o /dev/null -w "%{http_code}\n" http://server   # 200
kubectl -n netpol exec client-bad -- curl -s --max-time 3 http://server || echo BLOCKED
```

---

## Step 5 — Allow from another namespace

```bash
kubectl create ns trusted
kubectl label ns trusted purpose=trusted
kubectl -n trusted run remote --image=nicolaka/netshoot --command -- sleep 3600
kubectl -n trusted wait --for=condition=Ready pod/remote --timeout=60s

kubectl -n netpol patch networkpolicy allow-trusted --type=merge -p '
spec:
  ingress:
  - from:
    - podSelector: { matchLabels: { role: allowed } }
    - namespaceSelector: { matchLabels: { purpose: trusted } }
    ports:
    - { protocol: TCP, port: 80 }'

kubectl -n trusted exec remote -- curl -s -o /dev/null -w "%{http_code}\n" http://server.netpol.svc.cluster.local
```

---

## Step 6 — Egress policy

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: { name: dns-only, namespace: netpol }
spec:
  podSelector: { matchLabels: { role: denied } }
  policyTypes: [Egress]
  egress:
  - to:
    - namespaceSelector: {}
      podSelector: { matchLabels: { k8s-app: kube-dns } }
    ports:
    - { protocol: UDP, port: 53 }
EOF
kubectl -n netpol exec client-bad -- curl -s --max-time 3 http://1.1.1.1 || echo BLOCKED
kubectl -n netpol exec client-bad -- nslookup kubernetes.default
```

`client-bad` can resolve DNS but cannot reach anything else.

---

## Step 7 — Cleanup

```bash
kubectl delete ns netpol trusted
```

---

## What you learned
- Default-deny + explicit-allow is the safe pattern.
- `podSelector`, `namespaceSelector`, port lists.
- Ingress and Egress are separate `policyTypes`.
