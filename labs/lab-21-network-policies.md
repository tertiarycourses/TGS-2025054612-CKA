# Lab 21 — NetworkPolicy

By default every Pod can reach every other Pod. NetworkPolicies implement a firewall at the Pod level using allow-lists. CKA 2026 tests default-deny patterns, pod selector rules, namespace selector rules, and egress lockdown — typically as multi-step troubleshooting questions.

Run on https://killercoda.com/playgrounds/scenario/kubernetes

**Required software (free):**
- `kubectl` (pre-installed on Killercoda)
- `nicolaka/netshoot` debug image (pulled automatically)
- Calico CNI (pre-installed on Killercoda — enforces NetworkPolicy)

---

## Step 1 — Create test namespace and workloads

```bash
kubectl create ns netpol
kubectl -n netpol run server --image=nginx --labels="app=server"
kubectl -n netpol run client-ok  --image=nicolaka/netshoot \
  --labels="role=allowed" --command -- sleep 3600
kubectl -n netpol run client-bad --image=nicolaka/netshoot \
  --labels="role=denied" --command -- sleep 3600
kubectl -n netpol expose pod server --port=80
kubectl -n netpol wait --for=condition=Ready pod --all --timeout=60s
```

---

## Step 2 — Baseline: both clients can reach the server

```bash
kubectl -n netpol exec client-ok  -- curl -s -o /dev/null -w "%{http_code}\n" http://server
kubectl -n netpol exec client-bad -- curl -s -o /dev/null -w "%{http_code}\n" http://server
```

Both print `200` — no policy, no restriction.

---

## Step 3 — Apply default-deny ingress

```bash
cat > deny.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: netpol
spec:
  podSelector: {}
  policyTypes:
  - Ingress
EOF
kubectl apply -f deny.yaml
```

`podSelector: {}` matches all Pods. Empty `ingress:` means no ingress traffic is allowed.

```bash
kubectl -n netpol exec client-ok -- curl -s --max-time 3 http://server || echo "BLOCKED"
```

---

## Step 4 — Allow only the trusted client

```bash
cat > allow.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-trusted
  namespace: netpol
spec:
  podSelector:
    matchLabels:
      app: server
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: allowed
    ports:
    - protocol: TCP
      port: 80
EOF
kubectl apply -f allow.yaml
```

```bash
kubectl -n netpol exec client-ok  -- curl -s -o /dev/null -w "%{http_code}\n" http://server
kubectl -n netpol exec client-bad -- curl -s --max-time 3 http://server || echo "BLOCKED"
```

`client-ok` gets `200`; `client-bad` is blocked.

---

## Step 5 — Allow traffic from another namespace

```bash
kubectl create ns trusted
kubectl label ns trusted purpose=trusted
kubectl -n trusted run remote --image=nicolaka/netshoot --command -- sleep 3600
kubectl -n trusted wait --for=condition=Ready pod/remote --timeout=60s

cat > ns-allow.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-trusted-ns
  namespace: netpol
spec:
  podSelector:
    matchLabels:
      app: server
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          purpose: trusted
    ports:
    - protocol: TCP
      port: 80
EOF
kubectl apply -f ns-allow.yaml
kubectl -n trusted exec remote -- curl -s -o /dev/null -w "%{http_code}\n" \
  http://server.netpol.svc.cluster.local
```

---

## Step 6 — Egress lockdown: allow DNS only

```bash
cat > egress-dns.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: egress-dns-only
  namespace: netpol
spec:
  podSelector:
    matchLabels:
      role: denied
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
EOF
kubectl apply -f egress-dns.yaml
kubectl -n netpol exec client-bad -- nslookup kubernetes.default
kubectl -n netpol exec client-bad -- curl -s --max-time 3 http://1.1.1.1 || echo "EGRESS BLOCKED"
```

DNS works; all other egress is blocked.

---

## Step 7 — Clean up

```bash
kubectl delete ns netpol trusted
```

---

## Free online tools

- **NetworkPolicy docs**: https://kubernetes.io/docs/concepts/services-networking/network-policies/
- **NetworkPolicy visual editor**: https://editor.networkpolicy.io
- **Calico NetworkPolicy**: https://docs.tigera.io/calico/latest/network-policy/
- **killer.sh** — CKA mock exam: https://killer.sh
- **Kubernetes docs** (allowed in CKA exam): https://kubernetes.io/docs/

---

## What you learned

- Default-deny: `podSelector: {}` + `policyTypes: [Ingress]` with no `ingress:` list.
- `podSelector` in `from` restricts to matching Pods in the **same namespace**.
- `namespaceSelector` in `from` allows traffic from all Pods in matching namespaces.
- NetworkPolicies are additive — multiple policies combine with logical OR.
- Egress DNS-only is a common CKA exam pattern: allow UDP/TCP port 53, block everything else.
